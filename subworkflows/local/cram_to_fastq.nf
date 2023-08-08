include { crams_to_fastq } from '../../modules/crams_to_fastq.nf'
include { SAMTOOLS_COUNT } from '../../modules/local/samtools/count/main.nf'

workflow ANY_CRAM_TO_FASTQ {
    take:
        input  // channel: [ val(study_id), val(sample), path(cramfile) ]

    main:
        crams = create_cram_channel(input)
        SAMTOOLS_COUNT(crams)

        SAMTOOLS_COUNT.out.count
            .combine(crams, by: 0)
            .map{meta, count, cram -> [ meta + [ single_end: count.toInteger() == 0 ], cram ]}
            .set{meta_crams}

        crams_to_fastq(meta_crams)

    emit:
        study_sample_fastqs = crams_to_fastq.out.study_sample_fastqs
        lostcause = crams_to_fastq.out.lostcause
        numreads = crams_to_fastq.out.numreads
        info_file = crams_to_fastq.out.info_file
}

def create_cram_channel(input) {
    input.map{ it -> [ [study_id: it[0], id: it[1]], it[2] ] }
}
