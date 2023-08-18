#!/bin/bash

NEXUS_ADDR="${NEXUS_HTTP_SCHEME}://${NEXUS_PROXY_ADDR}"
INPUT="/tmp/install/requirements/conda-channels.txt"

# this script generates a set of correct .condarc configs for the channels given in files/requirements/conda-channels.txt
conda config --system --set env_prompt '({name}) '
conda config --system --set auto_update_conda false
conda config --system --set notify_outdated_conda false
conda config --system --prepend envs_dirs ~/my-conda-envs/

conda config --system --set channel_alias ${NEXUS_ADDR}/repository/

while IFS= read -r line
do
	conda config --system --prepend default_channels ${NEXUS_ADDR}/repository/${line}
	conda config --system --prepend channels ${line}
done < "$INPUT"

if [ `conda config --system --get auto_activate_base | wc -l` == 0 ]; then
    conda config --system --set auto_activate_base true
fi

conda config --system --prepend create_default_packages ipykernel
conda config --system --prepend create_default_packages trino-python-client