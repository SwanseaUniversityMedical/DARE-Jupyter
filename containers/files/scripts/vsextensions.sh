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
npm install -g yarn
mkdir tmpext

while IFS= read -r line
do
	DLURL=$(echo ${line})
	wget $DLURL -O - | tar -xzf - -C tmpext --strip-components=1
	cd tmpext
	vsce package --allow-star-activation
	OUTPUT=$(find . -name "*.vsix")
	# if no output is found, try building with yarn
	if [ ${#OUTPUT} -eq 0 ]
	then
		echo "No vsix file found"
		yarn install --ignore-scripts
		yarn run package
		vsce package --allow-star-activation
		OUTPUT=$(find . -name "*.vsix")
		if [ ${#OUTPUT} -eq 0 ]
		then
			yarn install
			vsce package --allow-star-activation
			OUTPUT=$(find . -name "*.vsix")
		fi
	fi
	echo "Installing $OUTPUT"
	code-server --install-extension $OUTPUT
	rm -rf *
	cd ..
done < "$INPUT"

rm -rf /tmp/install/scripts/tmpext

yarn cache clean --all