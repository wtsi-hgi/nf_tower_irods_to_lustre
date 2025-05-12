// import modules that depend on input mode:
include { imeta_study } from '../modules/imeta_study.nf'
include { iget_study_cram } from '../modules/iget_study_cram.nf'

// include workflow common to all input modes:
include { run_from_irods_tsv } from '../subworkflows/local/run_from_irods_tsv.nf'

workflow IRODS_TO_LUSTRE {
    if (params.run_mode == "study_id") {
		input_runs = (params.input_study_runs) ? params.input_study_runs : []

		imeta_study(params.input_studies, input_runs, [], params.filter_manual_qc)

        samples_irods_tsv = imeta_study.out.irods_samples_tsv.map{ sid, tsv -> tsv }
        work_dir_to_remove = imeta_study.out.work_dir_to_remove
    }

    else if (params.run_mode == "samples_list") {
    	imeta_study([], [], params.input_samples_list, params.filter_manual_qc)
    	samples_irods_tsv = imeta_study.out.irods_samples_tsv.map{ sid, tsv -> tsv }
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
