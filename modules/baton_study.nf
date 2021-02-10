process baton_study {
    tag "${study_id}"
    publishDir "${params.outdir}/samples/study_id_${study_id}/", mode: 'copy', pattern: "samples.tsv", overwrite: true
    publishDir "${params.outdir}/samples/study_id_${study_id}/", mode: 'copy', pattern: "samples_noduplicates.tsv", overwrite: true

    input: 
    val(study_id)

    output: 
    tuple val(study_id), path('samples.tsv'), emit: samples_tsv
    tuple val(study_id), path('samples_noduplicates.tsv'), emit: samples_noduplicates_tsv

    script:
    """
    bash $workflow.projectDir/../bin/baton.sh ${study_id}
    awk '!a[\$1]++' samples.tsv > samples_noduplicates.tsv 
    """
}
// awk removes duplicates as one sanger sample can have several run_id
