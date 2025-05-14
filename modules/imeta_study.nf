process imeta_study {
    tag = { (study_id) ? study_id : samples_file }
    publishDir "${params.metadata_dir}", mode: 'copy', pattern: "samples.tsv", overwrite: true
    publishDir "${params.metadata_dir}", mode: 'copy', pattern: "samples_noduplicates.tsv", overwrite: true

    cpus = 1
    memory = { 100.MB * task.attempt }

    when: 
    params.run_imeta_study

    input: 
    val(study_id)
    val(run_id)
    path(samples_file)
    val(filter_manual_qc)

    output: 
    tuple val(study_id), path('samples.tsv'), emit: irods_samples_tsv
    tuple val(study_id), path('samples_noduplicates.tsv'), emit: samples_noduplicates_tsv
    env(WORK_DIR), emit: work_dir_to_remove

    script:
    String study_id_cmd = (study_id) ? "--study_id ${study_id}" : ""
    String run_id_cmd = (run_id) ? "--run_ids ${run_id}" : ""
    String samples_file_cmd = (samples_file) ? "--samples_file ${samples_file}" : ""
    String manual_qc_cmd = (filter_manual_qc) ? "" : "--include_failing_samples"

    String template = """
    python $workflow.projectDir/bin/imeta_query.py %s %s %s %s
    awk '!a[\$2]++' samples.tsv > samples_noduplicates.tsv

    # Save work dir so that it can be removed onComplete of workflow, 
    # to ensure that this task Irods search is re-run on each run NF run, 
    # in case new sequencing samples are ready: 
    WORK_DIR=\$PWD
    """

    String.format(template, study_id_cmd, run_id_cmd, samples_file_cmd, manual_qc_cmd)
}
