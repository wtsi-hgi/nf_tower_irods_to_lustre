nextflow.enable.dsl=2

// All inputs are read from Nextflow config file "inputs.nf",
//  which is located in upstream Gitlab "nextflow_ci" repo (at same branch name).
// Meaning that if you wish to run pipeline with different parameters,
// you have to edit+commit+push that "inputs.nf" file, then rerun the pipeline.

// import modules that depend on input mode:
include { imeta_study } from './modules/imeta_study.nf'
include { imeta_study_lane } from './modules/imeta_study_lane.nf'
include { imeta_samples_csv } from './modules/imeta_samples_csv.nf'
include { gsheet_to_csv } from './modules/gsheet_to_csv.nf'
// module specific to google_spreadsheet input mode:
include { join_gsheet_metadata } from './modules/join_gsheet_metadata.nf'
include { iget_study_cram } from './modules/iget_study_cram.nf'

// include workflow common to all input modes:
include { run_from_irods_tsv } from './modules/run_from_irods_tsv.nf'

// params default
params.header = true

// print variables
if (params.header) {
log.info """\
				nf iRods to Lustre - HGI
		======================================="
		run mode						: ${params.run_mode}
		input_study_lanes				: ${params.input_study_lanes}
		input_studies					: ${params.input_studies}
		input_samples_csv				: ${params.input_samples_csv}
	 
		input_gsheet_name				: ${params.input_gsheet_name}
		input_google_creds				: ${params.input_google_creds}
		output_csv_name					: ${params.output_csv_name}
		input_sheet_name				: ${params.input_sheet_name}
		
		samples_to_process				: ${params.samples_to_process}

		run_imeta_study					: ${params.run_imeta_study} 
		run_imeta_samples				: ${params.run_imeta_samples}
		run_imeta_study_cellranger		: ${params.run_imeta_study_cellranger}
		run_iget_study_cellranger		: ${params.run_iget_study_cellranger}
		run_iget_study_cram				: ${params.run_iget_study_cram}
		run_crams_to_fastq				: ${params.run_crams_to_fastq}		
		run_metadata_visualisation		: ${params.run_metadata_visualisation}

		Name of outdir dir (DIRECTORY)	: ${params.outdir}
		output CRAMS dir (DIRECTORY)	: ${params.cram_output_dir}
		output reports dir (DIRECTORY)	: ${params.reportdir}
        """
         .stripIndent()
 }
 
workflow {

    if (params.run_mode == "study_id") {
        if (params.input_study_lanes) {
            imeta_study_lane( [params.input_studies, params.input_study_lanes] )

            samples_irods_tsv = imeta_study_lane.out.irods_samples_tsv
            work_dir_to_remove = imeta_study_lane.out.work_dir_to_remove
        }
        else{
            imeta_study(Channel.from(params.input_studies))

            samples_irods_tsv = imeta_study.out.irods_samples_tsv
            work_dir_to_remove = imeta_study.out.work_dir_to_remove
        } 
	}

    else if (params.run_mode == "csv_samples_id") {
        samples_irods_tsv = Channel.fromPath(params.input_samples_csv)
    }
    
    else if (params.run_mode == "google_spreadsheet") {
		i1 = Channel.from(params.input_gsheet_name)
		i2 = Channel.fromPath(params.input_google_creds)
		i3 = Channel.from(params.output_csv_name)
		i31 = Channel.from(params.input_sheet_name)
		
		gsheet_to_csv(i1,i2,i3,i31)
		i4 = Channel.from(params.google_spreadsheet_mode.input_gsheet_column)

		imeta_samples_csv(gsheet_to_csv.out.samples_csv, i4)

		samples_irods_tsv = imeta_samples_csv.out.irods_samples_tsv
		work_dir_to_remove = imeta_samples_csv.out.work_dir_to_remove.mix(gsheet_to_csv.out.work_dir_to_remove) 
	}
    // common to all input modes:
    run_from_irods_tsv(samples_irods_tsv)


    // list work dirs to remove (because they are Irods searches, so need to always rerun on each NF run):
    // these are removed on workflow.onComplete if (params.on_complete_uncache_irods_search), see below.
    //run_from_irods_tsv.out.ch_work_dir_to_remove.mix(work_dir_to_remove)
    //	.filter { it != "dont_remove" }
    //	.collectFile(name: 'irods_work_dirs_to_remove.csv', newLine: true, sort: true,
    //		     storeDir:params.outdir)

    if (params.run_mode == "google_spreadsheet") {
		log.info "else22 -> params.run_mode : ${params.run_mode}"
		// combine all samples tables (google spreadsheet, irods + cellranger metadata, cellranger /lustre file paths),
		//   by joining on common sample column:
		// the resulting combined tables can be fed directly as input to the Vireo deconvolution pipeline or QC pipeline.
		log.info "join_gsheet_metadata"
		join_gsheet_metadata(gsheet_to_csv.out.samples_csv,
					run_from_irods_tsv.out.ch_cellranger_metadata_tsv,
					run_from_irods_tsv.out.ch_file_paths_10x_tsv)
    }
}

workflow.onError {
    log.info "Pipeline execution stopped with the following message: ${workflow.errorMessage}" }

workflow.onComplete {
    log.info "Pipeline completed at: $workflow.complete"
    log.info "Command line: $workflow.commandLine"
    log.info "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
    
    if (params.on_complete_uncache_irods_search) {
		log.info "You have selected \"on_complete_uncache_irods_search = true\"; will therefore attempt to remove Irods work dirs to forcefully uncache them even if successful."
		if (! file("${params.outdir}/irods_work_dirs_to_remove.csv").isEmpty()) {
			log.info "file ${params.outdir}/irods_work_dirs_to_remove.csv exists and not empty ..."
			file("${params.outdir}/irods_work_dirs_to_remove.csv")
				.eachLine {  work_dir ->
				if (file(work_dir).isDirectory()) {
					log.info "removing work dir $work_dir ..."
					file(work_dir).deleteDir()   
				} 
			} 
		} 
	}
    
    if (params.on_complete_remove_workdir_failed_tasks) {
		log.info "You have selected \"on_complete_remove_workdir_failed_tasks = true\"; will therefore remove work dirs of all tasks that failed (.exitcode file not 0)."
		// work dir and other paths are hardcoded here ... :
		def proc = "bash ${projectDir}/bin/del_work_dirs_failed.sh ${workDir}".execute()
		def b = new StringBuffer()
		proc.consumeProcessErrorStream(b)
		log.info proc.text
		log.info b.toString() 
	}
}

