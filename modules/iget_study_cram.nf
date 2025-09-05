def makeCramFilename(String sampleName, String baseName) {
	def fixedBaseName = baseName.replaceAll("#", "_")
    return String.format("%s.%s.cram", sampleName, fixedBaseName)
}

process 'iget_study_cram' {
    tag "$meta.id:$cram_irods_object"
    publishDir "${params.cram_output_dir}", mode: "${params.copy_mode}"

    cpus = 1
    memory = { 512.MB * task.attempt }

    when: 
    params.run_iget_study_cram

    input:
    tuple val(meta), val(cram_irods_object)
    
    output:
    tuple val(meta), path("*.cram")                , emit: study_sample_cram
    tuple val(meta), path("*.cram"), path("*.crai"), emit: study_sample_cram_crai optional true

    script:
    def outname = makeCramFilename(meta.id, file(cram_irods_object).baseName)
    """
    iget -K -f -I -v ${cram_irods_object} ${outname}
    # get index file if exists:
    iget -K -f -I -v ${cram_irods_object}.crai ${outname}.crai || true
    """
}
