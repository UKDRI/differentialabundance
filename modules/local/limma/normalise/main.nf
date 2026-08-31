process LIMMA_NORMALISE {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    // The bioconductor-vsn package depends on limma (>=3.62.1), so this single
    // image provides both limma and vsn - no mulled container is needed.
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioconductor-vsn:3.74.0--r44h3df3fcb_1' :
        'biocontainers/bioconductor-vsn:3.74.0--r44h3df3fcb_1' }"

    input:
    tuple val(meta), path(matrix)

    output:
    tuple val(meta), path("*.normalised.tsv")     , emit: normalised
    tuple val(meta), path("*.R_sessionInfo.log")  , emit: session_info
    path "versions.yml"                           , emit: versions, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    template 'limma_normalise.R'

    stub:
    prefix              = task.ext.prefix   ?: "${meta.id}"
    """
    #!/usr/bin/env Rscript
    library(limma)
    a <- file("${prefix}.normalised.tsv", "w")
    close(a)
    a <- file("${prefix}.R_sessionInfo.log", "w")
    close(a)
    ## VERSIONS FILE
    r.version <- strsplit(version[['version.string']], ' ')[[1]][3]
    limma.version <- as.character(packageVersion('limma'))
    writeLines(
        c(
            '"${task.process}":',
            paste('    r-base:', r.version),
            paste('    bioconductor-limma:', limma.version)
        ),
        'versions.yml'
    )
    """
}
