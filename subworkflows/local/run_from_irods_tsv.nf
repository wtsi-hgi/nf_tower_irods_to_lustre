nextflow.enable.dsl=2

include { imeta_study_cellranger } from '../../modules/imeta_study_cellranger.nf'
include { iget_study_cram } from '../../modules/iget_study_cram.nf'
include { iget_study_cellranger } from '../../modules/iget_study_cellranger.nf'
include { crams_to_fastq } from '../../modules/crams_to_fastq.nf'
include { merge_crams } from '../../modules/merge_crams.nf'
include { ANY_CRAM_TO_FASTQ } from './cram_to_fastq.nf'

def create_input_channel(channel_samples_tsv) {
    channel_samples_tsv
        .splitCsv(header: true, sep: '\t')
        .map{ row -> tuple(
            [study_id: row.study_id, id: row.sample] + (row.is_paired_read ? [single_end: !row.is_paired_read.toBoolean()] : [:]),
            row.object
        ) }
        .filter { it[1] =~ /.cram$/ }
        .groupTuple(by: 0)
        .take(params.samples_to_process.toInteger())
        .transpose()
        .unique()
}

workflow run_from_irods_tsv {
    take: channel_samples_tsv
    main:

    if (params.run_mode == "study_id") {
        channel_samples_tsv = channel_samples_tsv.map{ study_id, samples_tsv -> samples_tsv }
    } else if (params.run_mode == "google_spreadsheet"){
        printErr("Not implemented yet")
	    exit 1
    }

    input = create_input_channel(channel_samples_tsv)

    // task to iget all Irods cram files of all samples
    iget_study_cram(input)

    if (params.run_mode == "google_spreadsheet") {
        // task to search Irods cellranger location for each sample:
        imeta_study_cellranger(
            channel_samples_tsv
                .map{study_id, samples_tsv -> samples_tsv}
                .splitCsv(header: true, sep: '\t')
                .map{row->tuple(row.study_id, row.sample, row.id_run)}
                .unique()
        )

        // store the list cellranger locations found into a single tsv table called "cellranger_irods_objects.csv"
        imeta_study_cellranger.out.study_id_sample_cellranger_object
            .map{study_id, sample, run_id, cellranger_irods_object, workdir ->
                 "${study_id},${sample},${run_id},${cellranger_irods_object},${workdir}"}
            .collectFile(name: 'cellranger_irods_objects.csv', newLine: true, sort: true,
                         seed: "study_id,sanger_sample_id,run_id,cellranger_irods_object,workdir",
                         storeDir:params.outdir)

        // task to iget the cellranger outputs from Irods:
        iget_study_cellranger(imeta_study_cellranger.out.study_id_sample_cellranger_object
	 		      .map{study_id, sample, run_id, cellranger_irods_object, workdir ->
	                   tuple(study_id, sample, cellranger_irods_object)}
			      .filter { it[2] != "cellranger_irods_not_found" })

        // prepare Lelands' pipeline inputs
        // --file_paths_10x    Tab-delimited file containing experiment_id and
        //                        path_data_10xformat columns.
        // prepare Lelands' pipeline input
        // --file_metadata     Tab-delimited file containing sample metadata.
        if (params.run_mode == "google_spreadsheet") {
            file_paths_10x_name = params.google_spreadsheet_mode.
                input_gsheet_name.replaceAll(/ /, "_") + ".file_paths_10x.tsv"
            file_metadata_name = params.google_spreadsheet_mode.
                input_gsheet_name.replaceAll(/ /, "_") + ".file_metadata.tsv" }
        else {
            file_paths_10x_name = "file_paths_10x.tsv"
            file_metadata_name = "file_metadata.tsv" }

        iget_study_cellranger.out.cellranger_filtered_outputs
	        .map{sample, filt10x_dir, filt_barcodes, filt_h5, bam ->
	             "${sample}\t${filt10x_dir}\t${sample}\tNA\tNA\t${filt_barcodes}\t${filt_h5}\t${bam}"}
            .collectFile(name: file_paths_10x_name,
                         newLine: true, sort: true,
                         seed: "experiment_id\tdata_path_10x_format\tshort_experiment_id\tncells_expected\tndroplets_include_cellbender\tdata_path_barcodes\tdata_path_filt_h5\tdata_path_bam_file",
                         storeDir:params.outdir)

        iget_study_cellranger.out.cellranger_metadata_tsv
            .collectFile(name: file_metadata_name,
                         newLine: false, sort: true, keepHeader: true,
                         storeDir:params.outdir)

        emit:
            imeta_study_cellranger.out.work_dir_to_remove
    }

    // task to merge cram files of each sample
    // merge by study_id and sample (Irods sanger_sample_id)
    merge_crams(iget_study_cram.out.study_sample_cram.groupTuple(by: 0))

    // collect cram paths
    merge_crams.out.info_file
        .collectFile(name: "cram_paths.csv", storeDir: params.metadata_dir, keepHeader: true)

    if (params.run_crams_to_fastq) {
        // task to convert merged crams to fastq
        ANY_CRAM_TO_FASTQ(merge_crams.out.study_sample_mergedcram)

        // store the number of reads in merged cram in output tables
        // lostcause has samples that did not pass the crams_to_fastq_min_reads input param,
        // which is the minimum number of reads in merged cram file to try and convert to fastq.gz
        ANY_CRAM_TO_FASTQ.out.lostcause
            .collectFile(name: "crams_to_fastq_lowreads.tsv",
                         newLine: false, sort: true, keepHeader: true,
                         storeDir: params.metadata_dir)

        // numreads has all samples that pass min number of reads number of reads in merged cram file
        ANY_CRAM_TO_FASTQ.out.numreads
            .collectFile(name: "crams_to_fastq_numreads.tsv",
                         newLine: false, sort: true, keepHeader: true,
                         storeDir: params.metadata_dir)

        // collect fastq paths
        ANY_CRAM_TO_FASTQ.out.info_file
            .collectFile(name: "fastq_paths.csv", storeDir: params.metadata_dir, keepHeader: true)
    }
}

// TODO:  here or main.nf:   // store work dirs to remove into tsv file for onComplete removal.
    //imeta_study.out.work_dir_to_remove.mix(
//	imeta_study_cellranger.out.work_dir_to_remove
//	    .filter { it != "dont_remove" })
//	.collectFile(name: 'irods_work_dirs_to_remove.csv', newLine: true, sort: true,
//		     storeDir:params.outdir)
    

//run_from_sanger_sample_id(Channel.fromPath(params.input_samples_csv)
//			  .splitCsv(header: true, sep: '\t')
//			  .map { row -> row.sample })
