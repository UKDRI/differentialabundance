#!/usr/bin/env Rscript

################################################
################################################
## Functions                                  ##
################################################
################################################

#' Parse out options from a string without recourse to optparse
#'
#' @param x Long-form argument list like --opt1 val1 --opt2 val2
#'
#' @return named list of options and values similar to optparse

parse_args <- function(x){
    args_list <- unlist(strsplit(x, ' ?--')[[1]])[-1]
    args_vals <- lapply(args_list, function(x) scan(text=x, what='character', quiet = TRUE))

    # Ensure the option vectors are length 2 (key/ value) to catch empty ones
    args_vals <- lapply(args_vals, function(z){ length(z) <- 2; z})

    parsed_args <- structure(lapply(args_vals, function(x) x[2]), names = lapply(args_vals, function(x) x[1]))
    parsed_args[ ( ! parsed_args %in%  c('', 'null')) & ! is.na(parsed_args)]
}

#' Flexibly read CSV or TSV files
#'
#' @param file Input file
#' @param header Passed to read.delim()
#' @param row.names Passed to read.delim()
#'
#' @return output Data frame

read_delim_flexible <- function(file, header = TRUE, row.names = NULL, check.names = FALSE){

    ext <- tolower(tail(strsplit(basename(file), split = "\\\\.")[[1]], 1))

    if (ext == "tsv" || ext == "txt") {
        separator <- "\\t"
    } else if (ext == "csv") {
        separator <- ","
    } else {
        stop(paste("Unknown separator for", ext))
    }

    read.delim(
        file,
        sep = separator,
        header = header,
        row.names = row.names,
        check.names = check.names
    )
}

#
#' Turn "null" or empty strings into actual NULL
#'
#' @param x Input option
#'
#' @return NULL or x
#'
nullify <- function(x) {
  if (is.character(x) && (tolower(x) == "null" || x == "")) NULL else x
}

#' log2-transform, refusing input that would produce -Inf or NaN
#'
#' A single -Inf is not confined to its own cell: normalizeQuantiles() averages
#' order statistics across columns, so it would poison that rank for every
#' sample. Fail loudly instead.
#'
#' @param x Numeric matrix
#' @param pseudocount Offset added before the transformation
#'
#' @return log2(x + pseudocount)
#'
log2_guarded <- function(x, pseudocount){
    bad <- sum(x + pseudocount <= 0, na.rm = TRUE)
    if (bad > 0){
        stop(paste0(
            "log2 transformation requires every value plus the pseudocount to be positive, but ",
            bad, " value(s) are <= 0 with --pseudocount ", pseudocount,
            ". Increase the pseudocount, and ensure that you supplied the correct raw input data."
        ))
    }
    log2(x + pseudocount)
}

################################################
################################################
## PARSE PARAMETERS FROM NEXTFLOW             ##
################################################
################################################

# Set defaults and classes

opt <- list(
    output_prefix = ifelse('$task.ext.prefix' == 'null', '$meta.id', '$task.ext.prefix'),
    count_file    = '$matrix',
    method        = NULL,
    pseudocount   = 1L,
    round_digits  = NULL
)
opt_types <- lapply(opt, class)

# Apply parameter overrides

args_opt <- parse_args('$task.ext.args')
for ( ao in names(args_opt)){
    if (! ao %in% names(opt)){
        stop(paste("Invalid option:", ao))
    }else{

        # Preserve classes from defaults where possible
        if (! is.null(opt[[ao]])){
            args_opt[[ao]] <- as(args_opt[[ao]], opt_types[[ao]])
        }
        opt[[ao]] <- args_opt[[ao]]
    }
}

if ( ! is.null(opt\$round_digits)){
    opt\$round_digits <- as.numeric(opt\$round_digits)
}

# If there is no option supplied, convert string "null" to NULL

keys <- c("method")
opt[keys] <- lapply(opt[keys], nullify)

# Check if required parameters have been provided

required_opts <- c('output_prefix', 'method')
missing <- required_opts[unlist(lapply(opt[required_opts], is.null)) | ! required_opts %in% names(opt)]

if (length(missing) > 0){
    stop(paste("Missing required options:", paste(missing, collapse=', ')))
}

# Check file inputs are valid

for (file_input in c('count_file')){
    if (is.null(opt[[file_input]])) {
        stop(paste("Please provide", file_input), call. = FALSE)
    }

    if (! file.exists(opt[[file_input]])){
        stop(paste0('Value of ', file_input, ': ', opt[[file_input]], ' is not a valid file'))
    }
}

################################################
################################################
## Finish loading libraries                   ##
################################################
################################################

library(limma)

################################################
################################################
## READ IN ABUNDANCE MATRIX                   ##
################################################
################################################

# The first column holds the feature identifier and is preserved verbatim, all
# remaining columns are the numeric abundance/ intensity matrix.

abundance.table <- read_delim_flexible(
    file = opt\$count_file,
    header = TRUE,
    row.names = NULL,
    check.names = FALSE
)

if (ncol(abundance.table) < 2){
    stop("Abundance matrix must have a feature identifier column plus at least one sample column")
}

feature_id_col <- colnames(abundance.table)[1]
feature_ids    <- abundance.table[[1]]

intensities <- as.matrix(abundance.table[, -1, drop = FALSE])

if (! is.numeric(intensities)){
    stop("Non-numeric values in the abundance matrix: all columns after the feature identifier column must be numeric")
}

# DIA data is NA-heavy. All the normalisation methods below tolerate NA, so
# rows are neither dropped nor imputed here.

################################################
################################################
## NORMALISE                                  ##
################################################
################################################

used_vsn <- FALSE

if (opt\$method == 'median'){

    # Median normalisation as understood in proteomics: scale the RAW
    # intensities to a common median, then log2. On the log scale that is a
    # per-sample shift, so every feature moves by the same amount and
    # between-sample log ratios are corrected uniformly across the abundance
    # range. Contrast limma's 'scale' below, which divides log2 values and so
    # corrects in proportion to a feature's own abundance.
    #
    # This mirrors limma's own EListRaw contract, where normalisation is
    # applied to the linear matrix "which will then be log2-transformed".

    norm_factors <- apply(intensities, 2, median, na.rm = TRUE)

    if (any(! is.finite(norm_factors)) || any(norm_factors <= 0)){
        stop("Median normalisation needs a positive, finite median for every sample: check for all-NA or all-zero columns")
    }

    norm_factors <- norm_factors / mean(norm_factors)
    normalised   <- log2_guarded(t(t(intensities) / norm_factors), opt\$pseudocount)

} else if (opt\$method %in% c('scale', 'quantile', 'cyclicloess')){

    # normalizeBetweenArrays() documents matrix input as "assumed to contain
    # log-transformed single-channel data", so log2-transform first. The offset
    # is configurable via --pseudocount (default 1, which keeps zeros finite);
    # it is not a limma requirement, so the user decides.
    #
    # Note that 'scale' is limma's scale normalisation, inherited from
    # two-colour M-values: it divides the log2 values to a common median, which
    # is not the additive median centring that 'median' above provides.

    normalised <- normalizeBetweenArrays(log2_guarded(intensities, opt\$pseudocount), method = opt\$method)

} else if (opt\$method == 'vsn'){

    # normalizeVSN() must be given RAW (un-logged) intensities: its docs state
    # "the input x should contain raw intensities", and vsn applies its own
    # variance-stabilising glog2 transform internally. So do not pre-log, and
    # --pseudocount does not apply here.

    if (! requireNamespace('vsn', quietly = TRUE)){
        stop("Method 'vsn' requires the vsn package, which is not installed")
    }
    normalised <- normalizeVSN(intensities)
    used_vsn <- TRUE

} else {
    stop(paste0(
        "Invalid normalisation method '", opt\$method,
        "'. Valid methods are: median, scale, quantile, cyclicloess, vsn"
    ))
}

# normalizeBetweenArrays()/ normalizeVSN() both return a matrix of the same
# size as the input, but be explicit about dimnames for safety

normalised <- as.matrix(normalised)
colnames(normalised) <- colnames(intensities)

if ( ! is.null(opt\$round_digits) && opt\$round_digits >= 0){
    normalised <- round(normalised, opt\$round_digits)
}

################################################
################################################
## Generate outputs                           ##
################################################
################################################

out_df <- data.frame(
    feature_ids,
    normalised,
    check.names = FALSE,
    stringsAsFactors = FALSE
)
colnames(out_df)[1] <- feature_id_col

write.table(
    out_df,
    file = paste(opt\$output_prefix, 'normalised.tsv', sep = '.'),
    col.names = TRUE,
    row.names = FALSE,
    sep = "\\t",
    quote = FALSE
)

################################################
################################################
## R SESSION INFO                             ##
################################################
################################################

sink(paste(opt\$output_prefix, "R_sessionInfo.log", sep = '.'))
print(sessionInfo())
sink()

################################################
################################################
## VERSIONS FILE                              ##
################################################
################################################

r.version <- strsplit(version[['version.string']], ' ')[[1]][3]
limma.version <- as.character(packageVersion('limma'))

versions <- c(
    '"${task.process}":',
    paste('    r-base:', r.version),
    paste('    bioconductor-limma:', limma.version)
)

if (used_vsn){
    versions <- c(versions, paste('    bioconductor-vsn:', as.character(packageVersion('vsn'))))
}

writeLines(versions, 'versions.yml')

################################################
################################################
################################################
################################################
