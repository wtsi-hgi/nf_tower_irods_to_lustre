process join_gsheet_metadata {
    tag "${gsheet_csv}"
    publishDir "${params.outdir}/join_gsheet_metadata/", mode: 'copy', overwrite: true
    
    when: 
    params.google_spreadsheet_mode.run_join_gsheet_metadata

    input: 
    path(gsheet_csv)
    path(cellranger_metadata_tsv)
    path(file_paths_10x_tsv)

    output: 
    path("nf_fetch_all_samples_metadata.tsv"), emit: nf_fetch_all_samples_metadata_tsv
    path("nf_fetch_samples_no_deconv.tsv"), emit: nf_fetch_samples_no_deconv_tsv
    path("nf_fetch_samples_to_deconv.tsv"), emit: nf_fetch_samples_to_deconv_tsv
    env(WORK_DIR), emit: work_dir_to_remove

    script:
    """
    python3 $workflow.projectDir/../bin/join_gsheet_metadata.py \\
       --gsheet_csv ${gsheet_csv} \\
       --cellranger_metadata_tsv ${cellranger_metadata_tsv} \\
       --file_paths_10x_tsv ${file_paths_10x_tsv}

    # Save work dir so that it can be removed onComplete of workflow, 
    # to ensure that this task Irods search is re-run on each run NF run, 
    # in case new sequencing samples are ready: 
    WORK_DIR=\$PWD
    """
}
