FROM jupyter/scipy-notebook:lab-4.0.3

ENV PATH=$PATH:/usr/lib/rstudio-server/bin
ENV XDG_DATA_HOME=/tmpvscode
ENV R_PROFILE=/opt/conda/lib/R/etc/Rprofile.site

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# Give NB_USER permission to chown the pip config file so we
# can populate it on startup, also fix the bash sourcing issue

# MKDIRs FIRST
RUN touch /etc/pip.conf && \
    mkdir /certs && \
    mkdir /tmpvscode && \
    mkdir -p /tmp/install/requirements && \
    mkdir -p /tmp/install/scripts && \
    mkdir -p /usr/local/bin/start-notebook.d/

# THEN CHOWN
RUN chown -R $NB_USER: /etc/pip.conf && \
    chown -R $NB_USER: /usr/local/bin/start-notebook.d/ && \
    chown -R $NB_USER: /tmpvscode && \
    chown -R $NB_USER: /tmp/install/scripts/ && \
    echo source /home/jovyan/.bashrc >> /etc/profile

# Install necessary packages for addons
RUN apt-get update && apt-get install -yq \
        gdebi-core \
        build-essential \
        psmisc \
        libssl-dev \
        libclang-dev \
        libpq5 \
        fonts-dejavu \
        gfortran \
        gcc && \
    ln -s /opt/conda/bin/R /usr/local/bin/R 

###################
### CLOUDBEAVER ###
###################

# Install Java for CloudBeaver
ENV JAVA_HOME=/opt/java/openjdk 
ENV PATH="$PATH:$JAVA_HOME/bin"

COPY --from=adoptopenjdk/openjdk11:jre-11.0.11_9-alpine "$JAVA_HOME" "$JAVA_HOME"

# Now install CloudBeaver
COPY --from=alleeex/cloudbeaver:22.2.3 /opt/cloudbeaver/ /opt/cloudbeaver/
COPY containers/files/cloudbeaver/conf /opt/cloudbeaver/conf
COPY containers/files/cloudbeaver/run-server.sh /opt/cloudbeaver/run-server.sh

RUN chmod +x /opt/cloudbeaver/run-server.sh && \
    chown -R $NB_USER: /opt/cloudbeaver && \
    mkdir -p /opt/cloudbeaver/workspace/user-projects/cbadmin/.dbeaver

# !!! MAKE THIS SOMETHING YOU MOUNT IN THE CHART
# COPY files/cloudbeaver/data-sources.json /opt/cloudbeaver/workspace/user-projects/cbadmin/.dbeaver/data-sources.json

###############
### RSTUDIO ###
###############
RUN wget http://security.debian.org/debian-security/pool/updates/main/o/openssl/libssl1.1_1.1.1n-0+deb11u5_amd64.deb && \
    dpkg -i libssl1.1_1.1.1n-0+deb11u5_amd64.deb && \
    rm libssl1.1_1.1.1n-0+deb11u5_amd64.deb 

RUN apt-get --fix-broken install

RUN wget https://download2.rstudio.org/server/jammy/amd64/rstudio-server-2023.06.1-524-amd64.deb && \
    dpkg -i rstudio-server-2023.06.1-524-amd64.deb && \
    rm rstudio-server-2023.06.1-524-amd64.deb 

#####################
### VSCODE SERVER ###
#####################
ENV CODE_VERSION=4.16.1
RUN curl -fOL -x "http://192.168.10.60:8080" https://github.com/coder/code-server/releases/download/v$CODE_VERSION/code-server_${CODE_VERSION}_amd64.deb \
    && dpkg -i code-server_${CODE_VERSION}_amd64.deb \
    && rm -f code-server_${CODE_VERSION}_amd64.deb \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && apt-get remove -y --purge gdebi-core

####################
### CERTIFICATES ###
####################
COPY containers/files/scripts/addcerts.sh ./
RUN chmod +x ./addcerts.sh && \
    chown -R $NB_USER: addcerts.sh

COPY containers/files/scripts/ /tmp/install/scripts/
RUN chmod +x /tmp/install/scripts/*.sh 

#####################
### USER CONFIGS  ###
#####################
USER ${NB_UID}

COPY containers/files/requirements/ /tmp/install/requirements/

RUN ls -a /tmp/install/requirements

# CONDA BASE ADDITIONS
RUN conda install --yes -n base conda-libmamba-solver && \
    conda config --set solver libmamba && \
    mamba env update --name base --file /tmp/install/requirements/conda-base.yaml && \
    mamba clean --all -f -y && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}" && \
    pip install -r /tmp/install/requirements/pip-standard.txt --no-cache-dir && \
    pip install -r /tmp/install/requirements/labextensions.txt --no-cache-dir && \
    jupyter labextension install plotlywidget luxwidget

# CONDA BASE ADDITIONS, CUSTOM PACKAGES
COPY dist/*.whl .
COPY containers/custom-packages/themes/*.whl .
RUN pip install jupyter_cloudbeaver_proxy-0.1-py3-none-any.whl --no-cache-dir && \
    pip install jupyter_rsession_proxy-2.2.0-py3-none-any.whl --no-cache-dir && \
    pip install base16_gruvbox_dark-1.0.0-py3-none-any.whl --no-cache-dir && \
    pip install base16_gruvbox_light-1.0.0-py3-none-any.whl --no-cache-dir && \
    pip install base16_mexico_light-1.0.0-py3-none-any.whl --no-cache-dir && \
    pip install base16_monokai-1.0.0-py3-none-any.whl --no-cache-dir && \
    pip install base16_nord-1.0.0-py3-none-any.whl --no-cache-dir && \
    pip install base16_one_dark-1.0.0-py3-none-any.whl --no-cache-dir && \
    pip install base16_outrun-1.0.0-py3-none-any.whl --no-cache-dir && \
    pip install base16_solarized_dark-1.0.0-py3-none-any.whl --no-cache-dir && \
    pip install base16_solarized_light-1.0.0-py3-none-any.whl --no-cache-dir && \
    pip install base16_summerfruit_light-1.0.0-py3-none-any.whl --no-cache-dir && \
    pip install city_lights-1.0.0-py3-none-any.whl --no-cache-dir && \
    rm *.whl

# JUPYTERLAB AND VSCODE EXTENSIONS
WORKDIR /tmp/install/scripts/
RUN ./vsextensions.sh 

# SESSION STARTUP
RUN mv /tmp/install/scripts/session_startup.sh /usr/local/bin/start-notebook.d/session_startup.sh && \
    mv /tmp/install/scripts/condarc_builder.sh /usr/local/bin/start-notebook.d/condarc_builder.sh

# REBUILD JUPYTER AND CLEANUP
RUN jupyter lab build --dev-build=False --minimize=True && \
    pip cache purge && \
    conda clean -a -y && \
    npm cache clean --force && \
    mamba clean --all -f -y && \
    rm -rf ~/.cache/yarn/*

WORKDIR "/home/${NB_USER}"

ENV XDG_DATA_HOME=
