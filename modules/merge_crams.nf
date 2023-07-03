process merge_crams {
    tag "${sample}"
    publishDir "${params.merged_crams_dir}", mode: "${params.copy_mode}", overwrite: true, pattern: "${sample}_merged.cram"

    when:
        params.run_merge_crams

    input:
        tuple val(study_id), val(sample), path(crams)

    output:
        tuple val(study_id), val(sample), path("${sample}_merged.cram"), emit: study_sample_mergedcram
        path("info.csv"), emit: info_file

    script:
    def cramfile = "${sample}_merged.cram"
    """
    samtools merge -@ ${task.cpus} -f $cramfile ${crams}

    echo "study_id,sample_id,cram_file" > info.csv
    echo "${study_id},${sample},${params.merged_crams_dir}/${cramfile}" >> info.csv
    """
}