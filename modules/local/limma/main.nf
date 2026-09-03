/*
 * limma-based between-sample normalisation for mass spectrometry intensities.
 *
 * All five processes share one container. bioconductor-vsn depends on limma
 * (>=3.54.0,<3.55.0 at this build), so the vsn image provides both packages and
 * the vsn process no longer needs a separate, site-local image. The r42 build
 * ships limma 3.54.x and R 4.2, matching environment.yml so the conda and
 * container routes resolve the same versions.
 */

process LIMMA_LOG_NORMALIZE_MEDIAN {
    tag "$meta"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioconductor-vsn:3.66.0--r42hc0cfd56_0' :
        'biocontainers/bioconductor-vsn:3.66.0--r42hc0cfd56_0' }"

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

process LIMMA_LOG2 {
    tag "$meta"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioconductor-vsn:3.66.0--r42hc0cfd56_0' :
        'biocontainers/bioconductor-vsn:3.66.0--r42hc0cfd56_0' }"

    input:
    tuple val(meta), path(matrix)

    output:
    tuple val(meta), path("*.log2.tsv")          , emit: normalised
    tuple val(meta), path("*.R_sessionInfo.log")    , emit: session_info
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    template 'log2_transform.R'
}

process LIMMA_LOG_NORMALIZE_SCALE {
    tag "$meta"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioconductor-vsn:3.66.0--r42hc0cfd56_0' :
        'biocontainers/bioconductor-vsn:3.66.0--r42hc0cfd56_0' }"

    input:
    tuple val(meta), path(matrix)

    output:
    tuple val(meta), path("*.lognorm_scale.tsv")          , emit: normalised
    tuple val(meta), path("*.R_sessionInfo.log")    , emit: session_info
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    template 'normalize_scale.R'
}

process LIMMA_LOG_NORMALIZE_QUANTILE {
    tag "$meta"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioconductor-vsn:3.66.0--r42hc0cfd56_0' :
        'biocontainers/bioconductor-vsn:3.66.0--r42hc0cfd56_0' }"

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
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioconductor-vsn:3.66.0--r42hc0cfd56_0' :
        'biocontainers/bioconductor-vsn:3.66.0--r42hc0cfd56_0' }"

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
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioconductor-vsn:3.66.0--r42hc0cfd56_0' :
        'biocontainers/bioconductor-vsn:3.66.0--r42hc0cfd56_0' }"

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
