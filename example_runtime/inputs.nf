params {

    run_mode = "google_spreadsheet" // you must choose either "study_id" or "csv_samples_id" or "google_spreadsheet".

    // mode "study_id" will list/iget all samples from an input list of Irods study_id(s).
    // mode "csv_samples_id" will iget all samples listed in input tsv file.
    // mode "google_spreadsheet" will iget all samples listed in input google spreadsheet column.

    // if you selected mode "study_id", define these:
    study_id_mode {
	run_imeta_study = true // whether to run task to list all samples and cram from study ids
	input_studies = ['6145'] // list of study_ids to pull, can be more than one (seperated by commas).
    }
    
    // if you selected mode "csv_samples_id", define these:
    csv_samples_id_mode {
	// will iget samples listed one-per-line in input file "samples.tsv":
	// it needs to be tab-separated and have a column name "sanger_sample_id" that matches Irods samples.
	input_samples_csv = "${projectDir}/../../inputs/samples_leo_35464.csv"
	input_samples_csv_column = "sanger_sample_id" // column for Irods sample IDs to search.
    }
    
    // if you selected mode "google_spreadsheet", define these:
    google_spreadsheet_mode {
	// will iget samples listed one-per-line in google spreadsheet:
	// mercury pipeline user must have been configured access to that spreadsheet.
	// it needs to have a column name "sanger_sample_id" that matches Irods samples.
	run_gsheet_to_csv = true // whether to run task to use google API and Service Account to convert google Spreadsheet with list of Irods samples IDs to local csv file.
	input_gsheet_name = "Submission_Data_Pilot_UKB" // name of google sheet, service account below must be granted access to that spreadsheet.
	input_google_creds = "google_api_credentials.json" // file path to service account credentials json, must have been granted access to spreadsheet
	output_csv_name = "Submission_Data_Pilot_UKB.csv" // name of sheet table converted to csv
	input_gsheet_column = "SANGER SAMPLE ID" // column for Irods sample IDs to search.
	run_join_gsheet_metadata = true // whether to run task to
	                                // combine all samples tables (google spreadsheet, irods + cellranger metadata, cellranger /lustre file paths),
	                                //   by joining on common sample column:
	                                // the resulting combined tables can be fed directly as input to the Vireo deconvolution pipeline or QC pipeline.
    }

    // input parameters common to all input modes:
    run_imeta_samples = true // whether to run task to list all samples and cram from provided list of samples IDs from csv input table (created from google Spreadsheet).
    run_imeta_study_cellranger = true // whether to run task to list all cellranger irods objects 
    run_iget_study_cellranger = true // whether to run task to iget all samples cellranger irods objects
    run_iget_study_cram = false // whether to run task to iget all samples cram files
    run_crams_to_fastq = false // whether to run task to merge and convert crams of each sample to fastq
    run_metadata_visualisation = true //whether to visualise the fetched rellranger metadata.
    crams_to_fastq_min_reads = "1000" // minimum number of reads in merged cram file to try and convert to fastq.gz 
    copy_mode = "rellink" // choose "rellink", "symlink", "move" or "copy" to stage in crams and cellranger data from work dir into results dir

    // the following are for one-off tasks run after workflow completion to clean-up work dir:
    on_complete_uncache_irods_search = false // will remove work dir (effectively un-caching) of Irods search tasks that need to be rerun on next NF run even if completed successfully.
    on_complete_remove_workdir_failed_tasks = false // will remove work dirs of failed tasks (.exitcode file not 0)
    // TODO: on_complete_remove_workdir_notsymlinked_in_results = false // will remove work dirs of tasks that are not symlinked anywhere in the results dir. This might uncache tasks.. use carefully..

}
