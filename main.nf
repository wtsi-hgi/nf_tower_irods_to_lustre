nextflow.enable.dsl=2
def printErr = System.err.&println

include { validateParameters; paramsSummaryLog } from 'plugin/nf-schema'

include { IRODS_TO_LUSTRE } from './workflows/irods_to_lustre.nf'

// validate inputs
validateParameters()
if (params.run_crams_to_fastq & !params.run_merge_crams) {
	log.error "Crams must be merged prior to conversion to fastq. Enable `run_merge_crams` option."
	exit 1
}

if (params.run_mode == "study_id") {
	if (!params.input_studies) {
		log.error "Study ID must be provided when using `run_mode = study_id`"
		exit 1
	}


} else if (params.run_mode == "csv_samples_id") {
	if (!params.input_samples_csv) {
		log.error "CSV file with input manifest must be provided when using `run_mode = csv_samples_id`"
		exit 1
	}
} else if (params.run_mode == "samples_list") {
	if (!params.input_samples_list) {
		log.error "List of sample IDs must be provided when using `run_mode = samples_list`"
		exit 1
	}
}

if (params.run_mode == "study_id" || params.run_mode == "samples_list") {
	if (!params.run_imeta_study) {
		log.error "Please enable `run_imeta_study` option to query iRODS metadata."
		exit 1
	}
}

// Print summary of supplied parameters
log.info paramsSummaryLog(workflow)

workflow {
    IRODS_TO_LUSTRE()
}

workflow.onError {
    log.info "Pipeline execution stopped with the following message: ${workflow.errorMessage}"
}

workflow.onComplete {
    log.info "Pipeline completed at: $workflow.complete"
    log.info "Command line: $workflow.commandLine"
    log.info "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
    
    // if (params.on_complete_uncache_irods_search) {
	//     log.info "You have selected \"on_complete_uncache_irods_search = true\"; will therefore attempt to remove Irods work dirs to forcefully uncache them even if successful."
    //     if (! file("${params.outdir}/irods_work_dirs_to_remove.csv").isEmpty()) {
    //         log.info "file ${params.outdir}/irods_work_dirs_to_remove.csv exists and not empty ..."
    //         file("${params.outdir}/irods_work_dirs_to_remove.csv")
    //         .eachLine {  work_dir ->
    //             if (file(work_dir).isDirectory()) {
    //                 log.info "removing work dir $work_dir ..."
    //                 file(work_dir).deleteDir()
    //             }
    //         }
    //     }
    // }
    //
    // if (params.on_complete_remove_workdir_failed_tasks) {
	//     log.info "You have selected \"on_complete_remove_workdir_failed_tasks = true\"; will therefore remove work dirs of all tasks that failed (.exitcode file not 0)."
    //     // work dir and other paths are hardcoded here ... :
    //     def proc = "bash ${projectDir}/bin/del_work_dirs_failed.sh ${workDir}".execute()
    //     def b = new StringBuffer()
    //     proc.consumeProcessErrorStream(b)
    //     log.info proc.text
    //     log.info b.toString()
	// }
}

