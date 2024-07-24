#!/bin/bash

#### CMD to run...
### gcloud projects list --format="table(projectId)" |grep  PATTERN-projects | xargs -n1 -i ./getIAMDump.sh \{\}  > results.txt
# gcloud projects list --format="csv(parent.id,name, lifecycleState, projectNumber,projectId,createTime)" | egrep '(FOLDER)' | awk -F',' '{print $5}'| xargs -n1 -i ./getProjectLiens.sh \{\}

project=$1
#PROJECT_NAME
#echo "getting IAM for project = $project"
#cmd="gcloud projects get-iam-policy $project --format='flattened(bindings)'| awk '{OFS=\":\"; print \"$project\",\$0}'"
cmd="gcloud alpha resource-manager liens list --project $project  --format=\"csv(NAME,ORIGIN,REASON)\"|awk '{OFS=\",\"; print \"$project\",\$0}'"
#echo "$cmd"
eval $cmd
