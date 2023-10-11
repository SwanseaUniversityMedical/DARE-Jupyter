#!/bin/bash

## this script resets and overwrites global settings and files for
## bash, conda, r, pip, vscode extensions

## make new .bashrc:
##  - initialise conda for shell interaction
##  - add cuda and tensor to the PATH
##  - dont ignore user's own .bash_profile, if it exists
NEXUS_ADDR="${NEXUS_HTTP_SCHEME}://${NEXUS_PROXY_ADDR}"

BASHRC_FILE=~/.bashrc

if [ -f $BASHRC_FILE ]; then
    rm "$BASHRC_FILE"
fi

echo "make new $BASHRC_FILE"

/opt/conda/bin/conda init --all --user --quiet

echo "
export PATH=\"/usr/local/cuda-11.6/bin:\$PATH\"
export LD_LIBRARY_PATH=\"/usr/local/cuda/lib64:\$LD_LIBRARY_PATH\"
export TENSORBOARD_PROXY_URL=\"/user/\$JUPYTERHUB_USER/proxy/%PORT%/\"

if [ -f ~/.bash_profile ]; then
    source ~/.bash_profile
fi
" >> $BASHRC_FILE

## reset .condarc to its essential config whilst preserving any user edits:
##   - point to nexus server for all channels
##   - define default channels
##   - add ~/my-conda-envs/ as a env dir
##   - set the dependency solver
##   - activate base if not already set to false

CONDARC_FILE=~/.condarc

echo "reset some options in $CONDARC_FILE"

INPUT="/tmp/install/requirements/conda-channels.txt"

# this script generates a set of correct .condarc configs for the channels given in files/requirements/conda-channels.txt
conda config --set env_prompt '({name}) '
conda config --set auto_update_conda false
conda config --set notify_outdated_conda false
conda config --set solver libmamba
conda config --prepend envs_dirs ~/my-conda-envs/

conda config --set channel_alias ${NEXUS_ADDR}/repository/

while IFS= read -r line
do
    conda config --prepend default_channels ${NEXUS_ADDR}/repository/${line}
    conda config --prepend channels ${line}
done < "$INPUT"

if [ `conda config --get auto_activate_base | wc -l` == 0 ]; then
    conda config --set auto_activate_base true
fi

conda config --prepend create_default_packages ipykernel
conda config --prepend create_default_packages trino-python-client

# Make sure these settings are also applied to  the base conda env .condarc file

BASE_CONDARC_FILE=/opt/conda/.condarc

echo "replace the base config in $BASE_CONDARC_FILE"

cat << EOF > $BASE_CONDARC_FILE
# Conda configuration see https://conda.io/projects/conda/en/latest/configuration.html

auto_update_conda: false
show_channel_urls: true
channels:
  - plotly
  - bioconda
  - pytorch
  - esri
  - nvidia
  - rapidsai
  - r
  - conda-forge
  - anaconda
env_prompt: '({name}) '
solver: libmamba
notify_outdated_conda: false
envs_dirs:
  - /home/jovyan/my-conda-envs/
channel_alias: ${NEXUS_ADDR}/repository/
default_channels:
  - ${NEXUS_ADDR}/repository/plotly
  - ${NEXUS_ADDR}/repository/bioconda
  - ${NEXUS_ADDR}/repository/pytorch
  - ${NEXUS_ADDR}/repository/esri
  - ${NEXUS_ADDR}/repository/nvidia
  - ${NEXUS_ADDR}/repository/rapidsai
  - ${NEXUS_ADDR}/repository/r
  - ${NEXUS_ADDR}/repository/conda-forge
  - ${NEXUS_ADDR}/repository/anaconda
auto_activate_base: true
create_default_packages:
  - ipykernel
  - trino-python-client
EOF


## setup default config for R:
##   - use nexus server as the package repo
##   - set jupyter mimetype for plots

R_SITE_PROFILE_FILE=/opt/conda/lib/R/etc/Rprofile.site

echo "overwrite $R_SITE_PROFILE_FILE"

echo "
local({
    # set package repo
    options(repos = c(\"Nexus\" = \"${NEXUS_ADDR}/repository/r-cran/\"))

    # set jupyter mimetype for plots
    options(jupyter.plot_mimetypes = c(\"text/plain\", \"image/png\", \"image/jpeg\", \"image/svg+xml\"))
})
" > $R_SITE_PROFILE_FILE


## setup default pip.conf
##   - set to use nexus server as repo

PIP_CONF_FILE=/etc/pip.conf

echo "overwrite $PIP_CONF_FILE"

echo "
[global]
trusted-host = ${NEXUS_PROXY_ADDR}
index = ${NEXUS_ADDR}/repository/pypi/pypi/
index-url = ${NEXUS_ADDR}/repository/pypi/pypi/simple
" > $PIP_CONF_FILE


## reset vscode extensions
##   - copy over everything we can
##   - leave anything else alone

VSCODE_EXT_PATH=~/.local/share/code-server/extensions

if [ ! -f $VSCODE_EXT_PATH ]; then
    mkdir -p $VSCODE_EXT_PATH
fi

echo "copying vscode extensions to $VSCODE_EXT_PATH"
cp -rf /tmpvscode/code-server/extensions/* ~/.local/share/code-server/extensions/