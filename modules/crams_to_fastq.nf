process crams_to_fastq {
    tag "${sample}"
    publishDir "${params.fastq_dir}", mode: "${params.copy_mode}", overwrite: true, pattern: "*.fastq.gz"

    when: 
        params.run_crams_to_fastq
    
    input: 
        tuple val(study_id), val(sample), path(cramfile)

    output: 
        tuple val(study_id), val(sample), path("*.fastq.gz"), emit: study_sample_fastqs
        path('*.lostcause.tsv'), emit: lostcause optional true
        path('*.numreads.tsv'), emit: numreads optional true
        path('info.csv'), emit: info_file

    script:
    """
    f1=${sample}_1.fastq.gz
    f2=${sample}_2.fastq.gz
    f0=${sample}.fastq.gz

    echo "study_id,sample_id,fastq1,fastq2" > info.csv

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
          -N              \\
          -F 0x900        \\
          -@ ${task.cpus} \\
          -1 \$f1 -2 \$f2 -0 \$f0 \\
          -
      sleep 2
      echo "${study_id},${sample},\$f1,\$f2" >> info.csv

    else
      echo -e "study_id\\tsample\\tnumreads" > ${sample}.lostcause.tsv
      echo -e "${study_id}\\t${sample}\\t\${numreads}" >> ${sample}.lostcause.tsv

    fi
    """
}
