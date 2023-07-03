process imeta_study {
    tag "${study_id}"
    publishDir "${params.metadata_dir}", mode: 'copy', pattern: "samples.tsv", overwrite: true
    publishDir "${params.metadata_dir}", mode: 'copy', pattern: "samples_noduplicates.tsv", overwrite: true

    when: 
    params.run_imeta_study

    input: 
    val(study_id)
    val(run_id)

    output: 
    tuple val(study_id), path('samples.tsv'), emit: irods_samples_tsv
    tuple val(study_id), path('samples_noduplicates.tsv'), emit: samples_noduplicates_tsv
    env(WORK_DIR), emit: work_dir_to_remove

    script:
    String run_id_cmd = (run_id) ? "--run_id ${run_id}" : ""
    String template = """
    python $workflow.projectDir/bin/imeta_study.py --baton \$BATON_PATH --study_id ${study_id} %s
    awk '!a[\$2]++' samples.tsv > samples_noduplicates.tsv

    # Save work dir so that it can be removed onComplete of workflow, 
    # to ensure that this task Irods search is re-run on each run NF run, 
    # in case new sequencing samples are ready: 
    WORK_DIR=\$PWD
    """
    String.format(template, run_id_cmd)
}
// awk removes duplicates as one sanger sample can have several run_id
