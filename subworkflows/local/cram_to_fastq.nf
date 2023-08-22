include { crams_to_fastq } from '../../modules/crams_to_fastq.nf'
include { SAMTOOLS_COUNT } from '../../modules/local/samtools/count/main.nf'

workflow ANY_CRAM_TO_FASTQ {
    take:
        crams  // channel: [ val(meta), path(cramfile) ]

    main:
        crams.branch {
            with_info   : it[0].containsKey("single_end")
            without_info: true
        }
        .set{crams}

        SAMTOOLS_COUNT(crams.without_info)
        SAMTOOLS_COUNT.out.count
            .combine(crams.without_info, by: 0)
            .map{meta, count, cram -> [ meta + [ single_end: count.toInteger() == 0 ], cram ]}
            .mix(crams.with_info)
            .set{meta_crams}

        crams_to_fastq(meta_crams)

    emit:
        study_sample_fastqs = crams_to_fastq.out.study_sample_fastqs
        lostcause = crams_to_fastq.out.lostcause
        numreads = crams_to_fastq.out.numreads
        info_file = crams_to_fastq.out.info_file
}
