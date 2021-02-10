#!/bin/bash -euo pipefail
export sample=$1
export run_id=$2

export run_id_2digits=$(echo ${run_id} | head -c2)
echo run_id is $run_id
echo run_id_2digits is $run_id_2digits

echo looking for cellranger data
ils /seq/${run_id}/cellranger/ | grep ${sample} > ${sample}.cellranger.found_in_irods.txt || true
ils /seq/illumina/${run_id_2digits}/${run_id}/cellranger/ | grep ${sample} >> ${sample}.cellranger.found_in_irods.txt || true
ils /seq/illumina/runs/${run_id_2digits}/${run_id}/cellranger/ | grep ${sample} >> ${sample}.cellranger.found_in_irods.txt || true
ils /seq/illumina/cellranger/ | grep ${sample} >> ${sample}.cellranger.found_in_irods.txt || true

if [ -s ${sample}.cellranger.found_in_irods.txt ] 
then 
        echo cellranger data found ${sample}
        cat ${sample}.cellranger.found_in_irods.txt  | awk '{print $2}' >> cellranger.object.txt
else
        echo cellranger data not found
fi
echo end cellranger fetch

rm -f ${sample}.cellranger.found_in_irods.txt 
