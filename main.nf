nextflow.enable.dsl=2
def printErr = System.err.&println

// import modules that depend on input mode:
include { imeta_study } from './modules/imeta_study.nf'
include { imeta_samples_csv } from './modules/imeta_samples_csv.nf'
include { iget_study_cram } from './modules/iget_study_cram.nf'

// include workflow common to all input modes:
include { run_from_irods_tsv } from './subworkflows/local/run_from_irods_tsv.nf'

include { validateParameters; paramsSummaryLog } from 'plugin/nf-schema'

// validate inputs
validateParameters()
if (params.run_crams_to_fastq & !params.run_merge_crams) {
	printErr("Error: Crams must be merged prior to conversion to fastq. Enable `run_merge_crams` option")
	exit 1
}

// Print summary of supplied parameters
log.info paramsSummaryLog(workflow)

workflow {

    if (params.run_mode == "study_id") {
		if (!params.input_study_runs) {
			params.input_study_runs = []
		}

		imeta_study(params.input_studies, params.input_study_runs, params.filter_manual_qc)

        samples_irods_tsv = imeta_study.out.irods_samples_tsv
        work_dir_to_remove = imeta_study.out.work_dir_to_remove
    }

    else if (params.run_mode == "csv_samples_id") {
        samples_irods_tsv = Channel.fromPath(params.input_samples_csv)
    }
    
    // common to all input modes:
    run_from_irods_tsv(samples_irods_tsv)


    // list work dirs to remove (because they are Irods searches, so need to always rerun on each NF run):
    // these are removed on workflow.onComplete if (params.on_complete_uncache_irods_search), see below.
    //run_from_irods_tsv.out.ch_work_dir_to_remove.mix(work_dir_to_remove)
    //	.filter { it != "dont_remove" }
    //	.collectFile(name: 'irods_work_dirs_to_remove.csv', newLine: true, sort: true,
    //		     storeDir:params.outdir)

}

workflow.onError {
    log.info "Pipeline execution stopped with the following message: ${workflow.errorMessage}" }

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

