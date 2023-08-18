#!/bin/bash

INPUT="/tmp/install/requirements/vsextensions.txt"

while IFS= read -r line
do
	code-server --install-extension "${line}"
done < "$INPUT"

INPUT="/tmp/install/requirements/vsextensions-directdl.txt"

# we have to manually build extensions from their github releases due to MSFT TOS preventing use
# of the MSFT Marketplace

npm install -g @vscode/vsce
mkdir tmpext

while IFS= read -r line
do
	DLURL=$(echo ${line})
	wget $DLURL -O - | tar -xzf - -C tmpext --strip-components=1
	cd tmpext
	vsce package
	OUTPUT=$(find . -name "*.vsix")
	echo "Installing $OUTPUT"
	code-server --install-extension $OUTPUT
	rm -rf *
	cd ..
done < "$INPUT"

rm -rf /tmp/install/scripts/tmpext