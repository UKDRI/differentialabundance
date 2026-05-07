process LIMMA_LOG_NORMALIZE_MEDIAN {
    tag "$meta"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioconductor-limma:3.54.0--r42hc0cfd56_0' :
        'biocontainers/bioconductor-limma:3.54.0--r42hc0cfd56_0' }"

    input:
    tuple val(meta), path(matrix)

    output:
    tuple val(meta), path("*.lognorm.tsv")          , emit: normalised
    tuple val(meta), path("*.R_sessionInfo.log")    , emit: session_info
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    template 'normalize_median.R'
}

process LIMMA_LOG_NORMALIZE_QUANTILE {
    tag "$meta"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioconductor-limma:3.54.0--r42hc0cfd56_0' :
        'biocontainers/bioconductor-limma:3.54.0--r42hc0cfd56_0' }"

    input:
    tuple val(meta), path(matrix)

    output:
    tuple val(meta), path("*.lognorm_quantile.tsv")          , emit: normalised
    tuple val(meta), path("*.R_sessionInfo.log")    , emit: session_info
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    template 'normalize_quantile.R'
}

process LIMMA_LOG_NORMALIZE_CYCLIC {
    tag "$meta"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioconductor-limma:3.54.0--r42hc0cfd56_0' :
        'biocontainers/bioconductor-limma:3.54.0--r42hc0cfd56_0' }"

    input:
    tuple val(meta), path(matrix)

    output:
    tuple val(meta), path("*.lognorm_cyclic.tsv")          , emit: normalised
    tuple val(meta), path("*.R_sessionInfo.log")    , emit: session_info
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    template 'normalize_cyclicloess.R'
}

process LIMMA_NORMALIZE_VSN {
    tag "$meta"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "/nfsdata/apptainer/r_proteomics-0.2.sif"

    input:
    tuple val(meta), path(matrix)

    output:
    tuple val(meta), path("*.norm_vsn.tsv")          , emit: normalised
    tuple val(meta), path("*.R_sessionInfo.log")    , emit: session_info
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    template 'normalize_vsn.R'
}
