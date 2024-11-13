process PYPGX_RUNNGSPIPELINE {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pypgx:0.25.0--pyh7e72e81_0':
        'biocontainers/pypgx:0.25.0--pyh7e72e81_0' }"

    input:
    tuple val(meta), path(vcf), path(tbi), path(coverage), path(control_stats), val(pgx_gene)
    tuple val(meta2), path(resource_bundle)
    val(assembly_version)

    output:
    tuple val(meta), val(pgx_gene), path("*pypgx_output"), emit: outdir
    path("versions.yml"), emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}_${pgx_gene}"
    def assembly = assembly_version ?: "GRCh38"

    """
    export MPLCONFIGDIR="/tmp/"
    export PYPGX_BUNDLE=${resource_bundle}/

    pypgx run-ngs-pipeline \\
        --assembly ${assembly} \\
        ${pgx_gene} \\
        ${prefix}_pypgx_output/ \\
        --variants ${vcf} \\
        --depth-of-coverage ${coverage} \\
        --control-statistics ${control_stats}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pypgx: \$(echo \$(pypgx -v 2>&1) | sed 's/.* //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}_${pgx_gene}"

    """
    mkdir ${prefix}_pypgx_output
    # zip program unavailable in container
    python -c 'import zipfile; zipfile.ZipFile("${prefix}_pypgx_output/results.zip", "w").close()'

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pypgx: \$(echo \$(pypgx -v 2>&1) | sed 's/.* //')
    END_VERSIONS
    """
}