process imeta_study_cellranger {
    tag "${sample} ${run_id} ${study_id}"
    
    publishDir "${params.outdir}/multiple_cellranger/${study_id}/", pattern: "${sample}.mult.cellranger.irods.txt", mode: "copy"
    
    when: 
    params.run_imeta_study_cellranger

    input: 
    tuple val(study_id), val(sample), val(run_id)

    output: 
    tuple val(study_id), val(sample), val(run_id), env(CELLRANGER_IRODS_OBJECT), env(WORK_DIR), emit: study_id_sample_cellranger_object
    env(WORK_DIR), emit: work_dir_to_remove
    tuple val(study_id), val(sample), val(run_id), path("${sample}.mult.cellranger.irods.txt"), emit: study_id_sample_mutiple_cellranger optional true

    script:
    """
    bash $workflow.projectDir/../bin/imeta_study_cellranger.sh ${sample} ${run_id}
    if [ -f cellranger.object.txt ] 
    then 
        echo file cellranger.object.txt found
        if [[ \$(wc -l <cellranger.object.txt) -ge 2 ]]
        then
          echo \"warning: more than one cellranger output found in Irods for sample ${sample}:\"
          echo \"....     will only download last ONE (sort | tail -n 1) of the multiple cellranger outputs from Irods.\"
          cat cellranger.object.txt | sort | tail -n 1 > ${sample}.mult.cellranger.irods.txt
        else
          echo \"One and only one cellranger output found in Irods for sample ${sample}\"
        fi
        CELLRANGER_IRODS_OBJECT=\$(cat cellranger.object.txt | sort | tail -n 1)
        WORK_DIR=dont_remove
        rm cellranger.object.txt
    else
        echo not found file cellranger.object.txt
        CELLRANGER_IRODS_OBJECT=cellranger_irods_not_found
        WORK_DIR=\$PWD
    fi
    """
}
