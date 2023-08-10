process crams_to_fastq {
    tag "${meta.id}"
    publishDir "${params.fastq_dir}", mode: "${params.copy_mode}", overwrite: true, pattern: "*.fastq.gz"

    when: 
        params.run_crams_to_fastq
    
    input:
        tuple val(meta), path(cramfile)

    output: 
        tuple val(meta), path("*.fastq.gz"), emit: study_sample_fastqs optional true
        path('*.lostcause.tsv'), emit: lostcause optional true
        path('*.numreads.tsv'), emit: numreads optional true
        path('info.csv'), emit: info_file

    script:
    def sample = meta.id
    def study_id = meta.study_id

    def f1 = "${sample}_1.fastq.gz"
    def f2 = "${sample}_2.fastq.gz"
    def f0 = "${sample}.fastq.gz"

    // for SE-reads NPG set neither read1 nor read2 bits
    def output = meta.single_end ? ""                        : "-N -1 ${f1} -2 ${f2}"
    def header = meta.single_end ? "fastq"                   : "fastq1,fastq2"
    def row    = meta.single_end ? "${params.fastq_dir}/$f0" : "${params.fastq_dir}/$f1,${params.fastq_dir}/$f2"

    """

    echo "study_id,sample_id,$header" > info.csv

    numreads=\$(samtools view -c -F 0x900 $cramfile)
    if (( \$numreads >= ${params.crams_to_fastq_min_reads} )); then
                              # -O {stdout} -u {no compression}
                              # -N {always append /1 and /2 to the read name}
                              # -F 0x900 (bit 1, 8, filter secondary and supplementary reads)

      echo -e "study_id\\tsample\\tnumreads" > ${sample}.numreads.tsv
      echo -e "${study_id}\\t${sample}\\t\${numreads}" >> ${sample}.numreads.tsv

      samtools collate    \\
          -O -u           \\
          -@ ${task.cpus} \\
          $cramfile pfx-${sample} | \\
      samtools fastq      \\
          -F 0x900        \\
          -@ ${task.cpus} \\
          -0 $f0 \\
          $output \\
          -
      sleep 2
      echo "${study_id},${sample},$row" >> info.csv

    else
      echo -e "study_id\\tsample\\tnumreads" > ${sample}.lostcause.tsv
      echo -e "${study_id}\\t${sample}\\t\${numreads}" >> ${sample}.lostcause.tsv

    fi
    """
}
