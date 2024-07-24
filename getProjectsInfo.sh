#!/bin/bash

rFile="f0"
tFile="f0.tmp"
folderId=""
getIAM=0
tmpDir="./tmp"
mkdir -p $tmpDir

pattern="id,display_name,parent_name"

function show_help {
echo "Usage: $0 <-f folderID | -o organizationID> [-i] "
echo "For example: ./$0 -f FOLDER_ID     -- for ORG -> FOLDER"
echo "For example: ./$0 -o ORG     -- for ORG  organization "
echo "For example: ./$0 -o ORG  -i  -- get projectInfo + IAM dump for ORG  organization "
}

while getopts hio:f: opt; do
case $opt in
h)
    show_help
    exit 0
    ;;
i)
   getIAM=1
   ;;
f)
if [ -z "$OPTARG" ]; then
    echo "Folder Id expected ..."
	echo ""
    show_help
    exit 1
else
    folderId="$OPTARG"
	echo "get folder info ..."
	gcloud alpha resource-manager folders list --folder=$folderId --format="csv(ID,DISPLAY_NAME,PARENT_NAME)" | egrep -v $pattern > $rFile
	cat $rFile | egrep -v $pattern > $tFile
	echo "$folderId,**root**,NA">>$rFile

fi
;;
o)
if [ -z "$OPTARG" ]; then
    echo "Folder Id expected ..."
	echo ""
    show_help
    exit 1
else
    folderId="$OPTARG"
	
	echo "get folder info ..."
	gcloud alpha resource-manager folders list --organization=$folderId --format="csv(ID,DISPLAY_NAME,PARENT_NAME)"|egrep -v $pattern > $rFile

	cat $rFile | egrep -v $pattern > $tFile
	echo "$orgId,**root**,NA">>$rFile

fi
;;
*)
    show_help >&2
    exit 1
    ;;
esac
done

if [ "$folderId" == "" ]; then
	show_help
	exit 1
fi

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

projectList=$tmpDir/projectList.$folderId.`date +%Y%m%d`.csv
iamList=$tmpDir/iamAudit.$folderId.`date +%Y%m%d`.csv

echo "folderPath,folderId,projectName,state,projectNumber,projectId,createTime" > $projectList
join -t ' ' -1 1 -2 1 -e '@' -o 0,1.2,2.2 f1 p1 | tr ' ' ','| awk -F',' '{OFS=","; print $3,$5,$6,$7,$8,$9,$10}' | tr '%' ' ' >> $projectList


echo " see results file: $projectList "
#rm -f f1 p1 f0 getallFolders.tmp

if [ "$getIAM" == "1" ]; then
   echo " Getting IAM info for $projectList"
   cat $projectList | egrep -v 'folderPath,folderId' | awk -F',' '{print $6}' | xargs -n1 -i ./getIAMDump.sh \{\} | awk -F',' '{OFS="|"; print $2,$1,$3,"add/remove"}'> $iamList
   echo "see $iamList for IAM access audit data"
fi
