process imeta_studyId_sampleName {
    tag "${study_id} - ${sample_name}"
    publishDir "${params.outdir}/imeta_study/study_id_${study_id}_sampleName_${sample_name}/", mode: 'copy', pattern: "samples.tsv", overwrite: true
    publishDir "${params.outdir}/imeta_study/study_id_${study_id}_sampleName_${sample_name}/", mode: 'copy', pattern: "samples_noduplicates.tsv", overwrite: true
    publishDir "${params.outdir}/", mode: 'copy', pattern: "samples.tsv", saveAs: { filename -> "${study_id}.$filename" }, overwrite: true
    publishDir "${params.outdir}/", mode: 'copy', pattern: "samples_noduplicates.tsv", saveAs: { filename -> "${study_id}.$filename" }, overwrite: true

    input: 
        val(study_id)
        val(sample_name)

    output: 
        tuple val(study_id), path('samples.tsv'), emit: irods_samples_tsv
        tuple val(study_id), path('samples_noduplicates.tsv'), emit: samples_noduplicates_tsv
        env(WORK_DIR), emit: work_dir_to_remove

    script:
    """
    echo inside imeta_study.sh - ${study_id} - ${sample_name}
    bash $workflow.projectDir/bin/imeta_studyId_sampleName.sh ${study_id} ${sample_name}
    awk '!a[\$1]++' samples.tsv > samples_noduplicates.tsv 

    # Save work dir so that it can be removed onComplete of workflow, 
    # to ensure that this task Irods search is re-run on each run NF run, 
    # in case new sequencing samples are ready: 
    WORK_DIR=\$PWD
    """
}
// awk removes duplicates as one sanger sample can have several run_id
