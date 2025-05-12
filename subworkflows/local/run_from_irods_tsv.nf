nextflow.enable.dsl=2

include { iget_study_cram } from '../../modules/iget_study_cram.nf'
include { crams_to_fastq } from '../../modules/crams_to_fastq.nf'
include { merge_crams } from '../../modules/merge_crams.nf'
include { ANY_CRAM_TO_FASTQ } from './cram_to_fastq.nf'

def create_input_channel(channel_samples_tsv) {
    channel_samples_tsv
        .splitCsv(header: true, sep: '\t')
        .map{ row -> tuple(
            [study_id: row.study_id, id: row.sample, n_reads: row.total_reads.toInteger()] +
            	(row.is_paired_read ? [single_end: !row.is_paired_read.toBoolean()] : [:]),
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

    input = create_input_channel(channel_samples_tsv)

    // task to iget all Irods cram files of all samples
    iget_study_cram(input)

    // task to merge cram files of each sample
    // merge by study_id and sample (Irods sanger_sample_id)
    merge_crams_input = iget_study_cram.out.study_sample_cram
    	.map{meta, cram ->
    		meta.remove('n_reads')
    		[meta, cram]
    	}
    	.groupTuple(by: 0)
    merge_crams(merge_crams_input)

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
