process gsheet_to_csv {
    tag "${gsheet}"
    publishDir "${params.outdir}/", mode: 'copy', pattern: "${output_csv_name}", overwrite: true
    
    when: 
    params.google_spreadsheet_mode.run_gsheet_to_csv

    input: 
    val(gsheet)
    path(creds_json)
    val(output_csv_name)

    output: 
    path("${output_csv_name}"), emit: samples_csv
    val(output_csv_name), emit: output_csv_name
    env(WORK_DIR), emit: work_dir_to_remove
    env(study_id), emit: study_id

    script:
    """
    python3 $workflow.projectDir/../bin/google_spreadsheet_to_csv.py \\
       --creds_json ${creds_json} --gsheet ${gsheet} --output_csv_name ${output_csv_name}

    # Save work dir so that it can be removed onComplete of workflow, 
    # to ensure that this task Irods search is re-run on each run NF run, 
    # in case new sequencing samples are ready: 
    WORK_DIR=\$PWD
    study_id=gsheet
    """
}
