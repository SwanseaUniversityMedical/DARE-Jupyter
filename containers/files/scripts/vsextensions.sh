#!/bin/bash

INPUT="/tmp/install/requirements/vsextensions.txt"

while IFS= read -r line
do
	code-server --install-extension "${line}"
done < "$INPUT"