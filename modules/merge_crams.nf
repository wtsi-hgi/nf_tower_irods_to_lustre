process merge_crams {
    tag "${meta.id}"
    publishDir "${params.merged_crams_dir}", mode: "${params.copy_mode}", overwrite: true, pattern: "${meta.id}_merged.cram"

    when:
        params.run_merge_crams

    input:
        tuple val(meta), path(crams)

    output:
        tuple val(meta), path("${meta.id}_merged.cram"), emit: study_sample_mergedcram
        path("info.csv"), emit: info_file

    script:
    def sample = meta.id
    def study_id = meta.study_id
    def cramfile = "${sample}_merged.cram"
    """
    samtools merge -@ ${task.cpus} -f $cramfile ${crams}

    echo "study_id,sample_id,cram_file" > info.csv
    echo "${study_id},${sample},${params.merged_crams_dir}/${cramfile}" >> info.csv
    """
}