process merge_crams {
    tag "${sample}"
    publishDir "${params.outdir}/crams_to_fastq/merged_crams/", mode: "${params.copy_mode}", overwrite: true, pattern: "${sample}_merged.cram"

    when:
        params.run_merge_crams

    input:
        tuple val(study_id), val(sample), path(crams)

    output:
        tuple val(study_id), val(sample), path("${sample}_merged.cram"), emit: study_sample_mergedcram

    script:
    def cramfile = "${sample}_merged.cram"
    """
    samtools merge -@ ${task.cpus} -f $cramfile ${crams}
    """
}