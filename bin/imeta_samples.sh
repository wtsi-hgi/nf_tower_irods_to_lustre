#!/usr/bin/env bash

export input_csv=$1
export column_samples=$2
echo input csv table is $input_csv
echo column samples is $column_samples

export samples_json_array=$(csvcut -c "$column_samples" $input_csv | \
				sed 1d | uniq | jq -R -s -c 'split("\n")[:-1]')
echo samples_json_array is $samples_json_array

rm -f samples.tmp.tsv
rm -f samples.tsv
printf 'target\tmanual_qc\tsample\tobject\tsample_supplier_name\tid_run\tis_paired_read\tstudy_id\tstudy\n' > samples.tmp.tsv

jq --argjson samples_json_array $samples_json_array -n '{avus: [
       {attribute: "sample", value: $samples_json_array, o: "in"}
      ]}' | \
	  baton-metaquery --zone seq --obj --avu | \
jq '.[] as $a| 
"\($a.avus | .[] | select(.attribute == "target") | .value)____\($a.avus | .[] | select(.attribute == "manual_qc") | .value)____\($a.avus | .[] | select(.attribute == "sample") | .value)____\($a.collection)/\($a.data_object)____\($a.avus | .[] | select(.attribute == "sample_supplier_name") | .value)____\($a.avus | .[] | select(.attribute == "id_run") | .value)____\($a.avus | .[] | select(.attribute == "is_paired_read") | .value)____\($a.avus | .[] | select(.attribute == "study_id") | .value)____\($a.avus | .[] | select(.attribute == "study") | .value)"' |\
    sed s"/$(printf '\t')//"g |\
    sed s"/\"//"g |\
    sed s"/____/$(printf '\t')/"g |\
sort | uniq | grep -P "^1\t1" >> samples.tmp.tsv

cat samples.tmp.tsv | awk '{print substr($0, index($0, $3))}' > samples.tsv 
rm samples.tmp.tsv

echo jq search study id done
echo see samples.tsv
