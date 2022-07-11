process imeta_study_lane {
    tag "${study_id}"
    publishDir "${params.outdir}/imeta_study_lane/study_id_${study_id}/", mode: 'copy', pattern: "samples.tsv", overwrite: true
    publishDir "${params.outdir}/imeta_study_lane/study_id_${study_id}/", mode: 'copy', pattern: "samples_noduplicates.tsv", overwrite: true
    publishDir "${params.outdir}/", mode: 'copy', pattern: "samples.tsv", saveAs: { filename -> "${study_id}.$filename" }, overwrite: true
    publishDir "${params.outdir}/", mode: 'copy', pattern: "samples_noduplicates.tsv", saveAs: { filename -> "${study_id}.$filename" }, overwrite: true

    when: 
    params.study_id_mode.run_imeta_study_lanes

    input: 
    tuple val(study_id), val(lane_id)

    output: 
    tuple val(study_id), path('samples.tsv'), emit: irods_samples_tsv
    tuple val(study_id), path('samples_noduplicates.tsv'), emit: samples_noduplicates_tsv
    env(WORK_DIR), emit: work_dir_to_remove

    script:
    """
    bash $workflow.projectDir/nf_deepvariant/bin/imeta_study_lane.sh ${study_id} ${lane_id}
    awk '!a[\$1]++' samples.tsv > samples_noduplicates.tsv 

    # Save work dir so that it can be removed onComplete of workflow, 
    # to ensure that this task Irods search is re-run on each run NF run, 
    # in case new sequencing samples are ready: 
    WORK_DIR=\$PWD
    """
}
// awk removes duplicates as one sanger sample can have several run_id
