process imeta_samples_csv {
    tag "${input_csv}"
    publishDir "${params.outdir}/imeta_study/study_id_${study_id}/", mode: 'copy', pattern: "samples.tsv", overwrite: true
    publishDir "${params.outdir}/", mode: 'copy', pattern: "samples.tsv", overwrite: true
    publishDir "${params.outdir}/imeta_study/study_id_${study_id}/", mode: 'copy', pattern: "samples_noduplicates.tsv", overwrite: true
    publishDir "${params.outdir}/", mode: 'copy', pattern: "samples_noduplicates.tsv", overwrite: true
    
    when: 
    params.run_imeta_samples

    input: 
    path(input_csv)
    val(irods_sample_column)

    output: 
    tuple env(study_id), path('samples.tsv'), emit: irods_samples_tsv
    env(WORK_DIR), emit: work_dir_to_remove
    tuple env(study_id), path('samples_noduplicates.tsv'), emit: samples_noduplicates_tsv
    env(study_id), emit: study_id

    script:
    """
    bash $workflow.projectDir/../bin/imeta_samples.sh $input_csv \"$irods_sample_column\"
    awk '!a[\$1]++' samples.tsv > samples_noduplicates.tsv 

    # Save work dir so that it can be removed onComplete of workflow, 
    # to ensure that this task Irods search is re-run on each run NF run, 
    # in case new sequencing samples are ready: 
    WORK_DIR=\$PWD
    study_id=tsv
    """
}
// awk removes duplicates as one sanger sample can have several run_id
