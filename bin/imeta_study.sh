#!/usr/bin/env bash
# to expand errors during the piping process 
set -e
set -o pipefail

study_id=$1

rm -f samples.tsv

printf 'sample\tobject\tid_run\tis_paired_read\tstudy_id\tstudy\n' > samples.tsv

jq --arg study_id $study_id -n '{avus: [
       {attribute: "target", value: "1", o: "="}, 
       {attribute: "manual_qc", value: "1", o: "="}, 
       {attribute: "type", value: ["cram","bam"], o: "in"}, 
      {attribute: "study_id", value: $study_id, o: "="}]}' |\
/software/sciops/pkgg/baton/2.0.1+1da6bc5bd75b49a2f27d449afeb659cf6ec1b513/bin/baton-metaquery \
		--zone seq --obj --avu |\
jq '.[] as $a| 
"\($a.avus | .[] | select(.attribute == "sample") | .value)____\($a.collection)/\($a.data_object)____\($a.avus | .[] | select(.attribute == "id_run") | .value)____\($a.avus | .[] | select(.attribute == "study_id") | .value)____\($a.avus | .[] | select(.attribute == "study") | .value)"' |\
    sed s"/$(printf '\t')//"g |\
    sed s"/\"//"g |\
    sed s"/____/$(printf '\t')/"g |\
sort | uniq >> samples.tsv

sample_num=$(awk '{if ($1 != "sample")print$1}' samples.tsv | uniq | wc -l)
let file_num=$(awk '{if ($2 != "object")print$2}' samples.tsv | sed 's/\.[crb]\+am//' | uniq | wc -l) 

if [[ $file_num != $sample_num ]] 
   then
      echo There are more files than samples, best not to use run_study_id to download
      exit 1
   else
      echo jq search study id done
fi
