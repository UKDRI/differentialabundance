#!/usr/bin/env Rscript

library(limma)
library(tools)

#' Flexibly read CSV or TSV files
#'
#' @param file Input file
#' @param header Passed to read.delim()
#' @param row.names Passed to read.delim()
#'
#' @return output Data frame

read_delim_flexible <- function(file, header = TRUE, row.names = NULL, check.names = FALSE){

    ext <- file_ext(file)

    if (ext == "tsv" || ext == "txt") {
        separator <- '\t'
    } else if (ext == "csv") {
        separator <- ','
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


### main
output_prefix = ifelse('$task.ext.prefix' == 'null', '$meta.id', '$task.ext.prefix')

# get matrix
mat <- read_delim_flexible('$matrix', check.names = FALSE)
col_names <- colnames(mat)
ids <- mat[,1]
mat_data <- as.matrix( mat[,c(2:dim(mat)[2])] )

# log-normalise normalize data
mat_data <- log2(mat_data + 1)
mat_data <- normalizeBetweenArrays(mat_data, method='scale')

mat_norm <- cbind(ids, as.data.frame(mat_data) )
colnames(mat_norm) <- col_names

# write output
write.table(
    mat_norm,
    file = paste(output_prefix, 'lognorm.tsv', sep = '.'),
    col.names = TRUE,
    row.names = FALSE,
    sep = '\t',
    quote = FALSE
)

################################################
################################################
## R SESSION INFO                             ##
################################################
################################################

sink(paste(output_prefix, "R_sessionInfo.log", sep = '.'))
print(sessionInfo())
sink()

################################################
################################################
## VERSIONS FILE                              ##
################################################
################################################

r.version <- strsplit(version[['version.string']], ' ')[[1]][3]
limma.version <- as.character(packageVersion('limma'))

writeLines(
    c(
        '"${task.process}":',
        paste('    r-base:', r.version),
        paste('    bioconductor-limma:', limma.version)
    ),
'versions.yml')