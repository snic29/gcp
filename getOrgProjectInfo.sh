#!/bin/bash

rFile="f0"
tFile="f0.tmp"

pattern="id,display_name,parent_name"

IFS=$'\r\n' GLOBIGNORE='*' command eval  'orgList=($(gcloud organizations list --format="csv(ID,display_name)" | grep -v "id,display_name"))'


idx=0
for i in "${orgList[@]}"
do
   echo "[$idx] : $i"
   idx=$((idx+1))
done
idx=$((idx-1))

if [ $idx -gt 0 ]; then
while true; do
    read -p "Select the organization entry [0] - [$idx] :  " orgIdx

    case $orgIdx in
      [0-$idx] ) echo "Selected $orgIdx" ; break;;
        * ) echo "Please answer number 0-$idx";;
    esac
done
else
      echo "default selection: $org"
fi

org=`echo ${orgList[$orgIdx]} |awk -F',' '{print $1}'`;
orgName=`echo ${orgList[$orgIdx]} |awk -F',' '{print $2}'`;
echo "Geting projects for $orgName ($org)"

echo "get folder info ..."
gcloud alpha resource-manager folders list --organization=$org --format="csv(ID,DISPLAY_NAME,PARENT_NAME)"|egrep -v $pattern > $rFile

cat $rFile | egrep -v $pattern > $tFile
echo "$org,**root**,NA">>$rFile

lines=`cat $tFile | egrep -v $pattern| wc -l | sed 's/ //g'`
while [ $lines -gt 0 ]
do 
        echo "lines=$lines"
	touch $tFile.new
	for folderLine in $(cat $tFile | egrep -v $pattern)
	do

		folderID=`echo $folderLine | awk -F',' '{print $1}'`
		folderName=`echo $folderLine | awk -F',' '{print $2}'`

		echo "f=$folderID; g=$folderName"
	        gcloud alpha resource-manager folders list --folder=$folderID --format="csv(ID,DISPLAY_NAME,PARENT_NAME)" | egrep -v $pattern > $rFile.1      	

		for fline in $(cat $rFile.1)
		do
	     #      echo "Input line: $fline ...."
		   fid=`echo $fline | awk -F',' '{print $1}'`
	           fname="$folderName/"`echo $fline | awk -F',' '{print $2}'`
		   parent=`echo $fline | awk -F',' '{print $3}'`
	           echo "$fid,$fname,$parent" >> $rFile
	     #      echo "processed line: $fid,$fname,$parent" 
		   
	           echo "$fid,$fname,$parent" >> $tFile.new

		done
	     #   read -p "Press any key..."	
	done
	mv $tFile.new $tFile
	lines=`cat $tFile | egrep -v $pattern| wc -l | sed 's/ //g'`
done
rm -f $rFile.1
rm -f $tFile

echo "Get project info...."
gcloud projects list --format="csv(parent.id,name, lifecycleState, projectNumber,projectId,createTime)" | egrep -v 'project_id,create_time' |egrep -v '^,' |tr ' ' '%'| awk -F',' '{print $1,$0}' | sort > p1

cat f0 |egrep -v 'display_name,parent_name' | awk -F',' '{print $1,$0}' | sort > f1

projectList=projectList.${orgName}_org.`date +%Y%m%d`.csv
echo "folderPath,folderId,projectName,state,projectNumber,projectId,createTime" > tmp/$projectList
join -t ' ' -1 1 -2 1 -e '@' -o 0,1.2,2.2 f1 p1 | tr ' ' ','| awk -F',' '{OFS=","; print $3,$5,$6,$7,$8,$9,$10}' | tr '%' ' ' | sort >> tmp/$projectList


echo " see results file: tmp/$projectList "
rm -f f1 p1 f0 getallFolders.tmp

