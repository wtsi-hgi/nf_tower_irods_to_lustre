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
echo pwd is \${PWD}

CRAM=\$(basename ${cram_irods_object})
echo basename cram is \${CRAM}

# get cram file, retry twice:
iget -K -f -v ${cram_irods_object} .
test -f \${CRAM} && sleep 10 && echo retry cram 1 && iget -K -f -v ${cram_irods_object} .
test -f \${CRAM} && sleep 10 && echo retry cram 2 && iget -K -f -v ${cram_irods_object} .
test -f \${CRAM} && echo get cram file failed && exit 1

# get index file if exists:
iget -K -f -v ${cram_irods_object}.crai . || true
test -f \${CRAM}.crai && sleep 10 && echo retry cram.crai 1 && iget -K -f -v ${cram_irods_object}.crai || true
test -f \${CRAM}.crai && sleep 10 && echo retry cram.crai 1 && iget -K -f -v ${cram_irods_object}.crai || true
   """
}
