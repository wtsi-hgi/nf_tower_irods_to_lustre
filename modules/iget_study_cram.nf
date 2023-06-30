process 'iget_study_cram' {
    tag "$sample:$cram_irods_object"
    publishDir "${params.cram_output_dir}", mode: "${params.copy_mode}"
    
    when: 
    params.run_iget_study_cram

    input:
    tuple val(study_id), val(sample), val(cram_irods_object)
    
    output:
    tuple val(study_id), val(sample), path("*.cram"), emit: study_sample_cram
    tuple val(study_id), val(sample), path("*.cram"), path("*.crai"), emit: study_sample_cram_crai optional true

    script:
    filename = file(cram_irods_object).baseName
    (parsed, run_parsed, lane_parsed, cell_parsed) = (filename =~ /(\d+)_(\d+)#(\d+)/)[0]
    outname = String.format("%s.%s_%s_%s.cram", sample, run_parsed, lane_parsed, cell_parsed)
    """
    iget -K -f -I -v ${cram_irods_object} ${outname}
    # get index file if exists:
    iget -K -f -I -v ${cram_irods_object}.crai ${outname}.crai || true
    """
}
