#!/usr/bin/env bash
study_id=$1

rm -f samples.tsv

printf 'sample\tobject\tsample_supplier_name\tid_run\tis_paired_read\tstudy_id\tstudy\n' > samples.tsv

jq --arg study_id $study_id -n '{avus: [
       {attribute: "study_id", value: $study_id, o: "="}, 
       {attribute: "manual_qc", value: "1", o: "="}, 
      {attribute: "target", value: "1", o: "="}]}' |\
baton-metaquery \
		--zone seq --obj --avu |\
jq '.[] as $a| 
"\($a.avus | .[] | select(.attribute == "sample") | .value)____\($a.collection)/\($a.data_object)____\($a.avus | .[] | select(.attribute == "sample_supplier_name") | .value)____\($a.avus | .[] | select(.attribute == "id_run") | .value)____\($a.avus | .[] | select(.attribute == "is_paired_read") | .value)____\($a.avus | .[] | select(.attribute == "study_id") | .value)____\($a.avus | .[] | select(.attribute == "study") | .value)"' |\
    sed s"/$(printf '\t')//"g |\
    sed s"/\"//"g |\
    sed s"/____/$(printf '\t')/"g |\
sort | uniq >> samples.tsv

echo jq search study id done
