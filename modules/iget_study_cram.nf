process 'iget_study_cram' {
    tag "$meta.id:$cram_irods_object"
    publishDir "${params.cram_output_dir}", mode: "${params.copy_mode}"
    
    when: 
    params.run_iget_study_cram

    input:
    tuple val(meta), val(cram_irods_object)
    
    output:
    tuple val(meta), path("*.cram")                , emit: study_sample_cram
    tuple val(meta), path("*.cram"), path("*.crai"), emit: study_sample_cram_crai optional true

    script:
    def sample = meta.id
    def filename = file(cram_irods_object).baseName
    def (parsed, prefix, cell_parsed) = (filename =~ /([\d_]+)#(\d+)/)[0]
    def outname = String.format("%s.%s_%s.cram", sample, prefix, cell_parsed)
    """
    iget -K -f -I -v ${cram_irods_object} ${outname}
    # get index file if exists:
    iget -K -f -I -v ${cram_irods_object}.crai ${outname}.crai || true
    """
}
