#!/bin/bash

rFile="getAllFolders.results"
tFile="getallFolders.tmp"

org_id=$1
pattern="id,display_name,parent_name"

echo $pattern > $rFile 
echo "$org_id,**root**,NA">>$rFile

gcloud alpha resource-manager folders list --organization=$org_id --format="csv(ID,DISPLAY_NAME,PARENT_NAME)"|egrep -v $pattern > $rFile

cat $rFile | egrep -v $pattern > $tFile


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
