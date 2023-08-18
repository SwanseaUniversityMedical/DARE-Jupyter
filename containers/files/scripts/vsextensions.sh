#!/bin/bash

INPUT="/tmp/install/requirements/vsextensions.txt"

while IFS= read -r line
do
	code-server --install-extension "${line}"
done < "$INPUT"

INPUT="/tmp/install/requirements/vsextensions-directdl.txt"
while IFS= read -r line
do
	DLURL=$(echo ${line} | cut -d "," -f 2)
	PNAME=$(echo ${line} | cut -d "," -f 1)
	FNAME="$(echo ${DLURL} | cut -d "/" -f 8).$(echo ${DLURL} | cut -d "/" -f 10)-$(echo ${DLURL} | cut -d "/" -f 11).vsix"
	wget -c $DLURL -O $FNAME
	code-server --install-extension $FNAME
	rm $FNAME
	# have to sleep to avoid msft rate limiting
	sleep 60
done < "$INPUT"