process 'iget_study_cram' {
    tag "$sample"
    publishDir "${params.outdir}/iget_study_cram/${study_id}/${sample}/", mode: "${params.copy_mode}"
    
    when: 
    params.run_iget_study_cram

    input:
    tuple val(study_id), val(sample), val(cram_irods_object)
    
  output:
    tuple val(study_id), val(sample), path("*.cram"), emit: study_sample_cram
    tuple val(study_id), val(sample), path("*.cram"), path("*.crai"), emit: study_sample_cram_crai optional true

  script:
    """
iget -K -f -v ${cram_irods_object}
# get index file if exists:
iget -K -f -v ${cram_irods_object}.crai || true
   """
}
