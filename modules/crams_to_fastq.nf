process crams_to_fastq {
    tag "${sample}-${study_id}"
    publishDir "${params.outdir}/crams_to_fastq/fastq/${study_id}/${sample}/", mode: "${params.copy_mode}", overwrite: true, pattern: "*.fastq.gz"
    publishDir "${params.outdir}/crams_to_fastq/merged_crams/${study_id}/${sample}/", mode: "${params.copy_mode}", overwrite: true, pattern: "${study_id}.${sample}_merged.cram"
    
    when: 
    params.run_crams_to_fastq
    
    input: 
    tuple val(study_id), val(sample), path(crams) 

    output: 
    tuple val(study_id), val(sample), path("*.fastq.gz"), emit: study_sample_fastqs
    tuple val(study_id), val(sample), path("${study_id}.${sample}_merged.cram"), emit: study_sample_mergedcram
    path('*.lostcause.tsv'), emit: lostcause optional true 
    path('*.numreads.tsv'), emit: numreads optional true 
    env(study_id), emit: study_id

    script:
    def cramfile = "${study_id}.${sample}_merged.cram"
    """
    export REF_PATH=/lustre/scratch117/core/sciops_repository/cram_cache/%2s/%2s/%s:/lustre/scratch118/core/sciops_repository/cram_cache/%2s/%2s/%s:URL=http:://sf2-farm-srv1.internal.sanger.ac.uk::8000/%s
    export PATH=/opt/conda/envs/nf-core-rnaseq-1.3/bin:/opt/conda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    
    samtools merge -@ ${task.cpus} -f $cramfile ${crams}
    f1=${study_id}.${sample}_1.fastq.gz
    f2=${study_id}.${sample}_2.fastq.gz
    f0=${study_id}.${sample}.fastq.gz
    numreads=\$(samtools view -c -F 0x900 $cramfile)
    if (( \$numreads >= ${params.crams_to_fastq_min_reads} )); then
                              # -O {stdout} -u {no compression}
                              # -N {always append /1 and /2 to the read name}
                              # -F 0x900 (bit 1, 8, filter secondary and supplementary reads)
      echo -e "study_id\\tsample\\tnumreads" > ${study_id}.${sample}.numreads.tsv
      echo -e "${study_id}\\t${sample}\\t\${numreads}" >> ${study_id}.${sample}.numreads.tsv
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
      find . -name \"*.fastq.gz\" -type 'f' -size -160k -delete
    else
      echo -e "study_id\\tsample\\tnumreads" > ${study_id}.${sample}.lostcause.tsv
      echo -e "${study_id}\\t${sample}\\t\${numreads}" >> ${study_id}.${sample}.lostcause.tsv
    fi

    study_id=gsheet
    """
}
