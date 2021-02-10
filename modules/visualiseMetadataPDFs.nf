process visualiseMetadata{


  publishDir "${params.outdir}/PDFs/", mode: 'copy', overwrite: true
  

  when:
  params.run_metadata_visualisation

  input:
  path(my_channel)

  script:

  """
  
  python $workflow.projectDir/../bin/main_PDF_visualisation.py $my_channel

  """

}
