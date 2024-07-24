#!/bin/bash

for scopesInfo in $(
    gcloud compute instances list \
        --format="csv[no-heading](name,id,serviceAccounts[].email.list(),
                      serviceAccounts[].scopes[].map().list(separator=;))")
do
      IFS=',' read -r -a scopesInfoArray<<< "$scopesInfo"
      NAME="${scopesInfoArray[0]}"
      ID="${scopesInfoArray[1]}"
      EMAIL="${scopesInfoArray[2]}"
      SCOPES_LIST="${scopesInfoArray[3]}"

      echo "NAME: $NAME, ID: $ID, EMAIL: $EMAIL"
      echo ""
      IFS=';' read -r -a scopeListArray<<< "$SCOPES_LIST"
      for SCOPE in  "${scopeListArray[@]}"
      do
        echo "  SCOPE: $SCOPE"
      done
done
