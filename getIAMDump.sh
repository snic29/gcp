#!/bin/bash

#### CMD to run...
### gcloud projects list --format="table(projectId)" |grep  pattern_directory_name | xargs -n1 -i ./getIAMDump.sh \{\}  > results.txt
# gcloud projects list --format="csv(parent.id,name, lifecycleState, projectNumber,projectId,createTime)" | egrep '(folder1|folder2|...)' | awk -F',' '{print $5}'| xargs -n1 -i ./getIAMDump.sh \{\} | awk -F',' '{OFS="|"; print $2,$1,$3,"add/remove"}'> 20180910.iamdump.txt

project=$1
#example project name
#echo "getting IAM for project = $project"
#cmd="gcloud projects get-iam-policy $project --format='flattened(bindings)'| awk '{OFS=\":\"; print \"$project\",\$0}'"
cmd="gcloud projects get-iam-policy $project --format=json | jq '.bindings[]' | jq '{member: .members[],role}' | jq 'flatten|@csv' | tr -d '\"' |tr -d '\\\'| awk '{OFS=\",\"; print \"$project\",\$0}'"
#echo "$cmd"
eval $cmd
