#!/bin/bash

for project in  $(gcloud projects list --format="value(projectId)"| grep -i PATTERN)
do
  checkComputeSvc=`gcloud  services list --enabled  --filter='NAME:compute*' --project $project`
  if [[ $checkComputeSvc =~ .*NAME.* ]]; then
     # cump[ute api enabled
     vm=`gcloud compute instances list --project $project --filter "networkInterfaces[].accessConfigs[].natIP = $1"`
     echo "Checking project : $project ..."
     if [[ $vm =~ .*NAME.* ]]; then
         echo $vm
     fi
  fi

done
