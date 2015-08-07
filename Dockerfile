############################################################
# Dockerfile to build Medical Imaging Galaxy
# Based on Ubuntu 14.04
############################################################

# Set the base image to Ubuntu
FROM ubuntu:trusty

# Update the sources list and install basic packages
RUN apt-get update && apt-get install -y tar less git curl vim wget unzip netcat software-properties-common

# Add neurodebian packages to apt-get and condor to apt-sources
# TODO: This is required by many neuroimaging tools, but it should really be placed somewhere else (within tool?). For now, we will have to live with it.
RUN wget -O- http://neuro.debian.net/lists/trusty.us-ca.full | tee /etc/apt/sources.list.d/neurodebian.sources.list && \
    apt-key adv --recv-keys --keyserver hkp://pgp.mit.edu:80 2649A5A9 && \
    echo "deb [arch=amd64] http://research.cs.wisc.edu/htcondor/debian/development/ wheezy contrib" >> /etc/apt/sources.list && \
    echo "deb [arch=amd64] http://research.cs.wisc.edu/htcondor/debian/stable/ wheezy contrib" >> /etc/apt/sources.list && \
    wget -qO - http://research.cs.wisc.edu/htcondor/debian/HTCondor-Release.gpg.key | apt-key add - && \
    apt-get update

RUN apt-get install -y \
    python-pip \
    python-virtualenv \
    mricron \
    fsl-core \
    afni \
    condor

# TODO: Configure uwsgi
# RUN apt-get install -y \
#     uwsgi \
#     uwsgi-plugin-python

# Configure AFNI and FSL
# TODO: Only necessary because of tools that depend on these. Its installation should actually be handled by the tools themselves.
RUN ["/bin/bash", "-c", "source /etc/afni/afni.sh"]
RUN ["/bin/bash", "-c", "source /etc/fsl/fsl.sh"]

# Configure condor submitter
ADD ./docker/galaxy/resources/condor_config.local /etc/condor/condor_config.local
# Need to restart condor so config is picked up
RUN /etc/init.d/condor restart

# Update python setuptools from source
# TODO: Only necessary because we have to build niibabel and pydicom from source. Those are required by some custom datatypes (datatypes dependencies cannot be resolved outside tool execution in Galaxy). To remove this dependency, we must rewrite some parts of those datatypes first.
RUN wget https://bitbucket.org/pypa/setuptools/downloads/ez_setup.py -O - | python

# Configure Galaxy Application
ENV GALAXY_HOME /usr/local/galaxy
ENV GALAXY_DATA /data

# Add project to the image
ADD galaxy $GALAXY_HOME

# Expose Galaxy data dir as a mountable volume
VOLUME $GALAXY_DATA

# Prepare startup and scramble eggs manually (see above TODO comment)
WORKDIR $GALAXY_HOME

RUN ./scripts/common_startup.sh
RUN python scripts/scramble.py -c config/galaxy.ini.sample -e pydicom
RUN python scripts/scramble.py -c config/galaxy.ini.sample -e nibabel

# Add
ADD config/galaxy.ini.docker config/galaxy.ini
ADD config/shed_tool_conf.xml.docker config/shed_tool_conf.xml
ADD config/job_conf.xml.docker config/job_conf.xml

ENV GALAXY_CONFIG_DATABASE_CONNECTION postgresql://galaxy:calvin@postgres:5432/galaxy \
    GALAXY_CONFIG_FILE_PATH /data/files \
    GALAXY_CONFIG_NEW_FILE_PATH /data/files \
    GALAXY_CONFIG_TOOL_DEPENDENCY_DIR /data/tool_shed_deps \
    GALAXY_CONFIG_JOB_WORKING_DIRECTORY /data/job_working_directory \
    GALAXY_CONFIG_CLUSTER_FILES_DIRECTORY /data/pbs \
    GALAXY_CONFIG_TEMPLATE_CACHE_PATH /data/compiled_templates \
    GALAXY_CONFIG_CITATION_CACHE_DATA_DIR /data/citations/data \
    GALAXY_CONFIG_CITATION_CACHE_LOCK_DIR /data/citations/lock \
    GALAXY_CONFIG_OBJECT_STORE_CACHE_PATH /data/files \
    GALAXY_CONFIG_ADMIN_USERS dev@mig.ime.usp.br \
    GALAXY_CONFIG_OVERRIDE_DEBUG=False

EXPOSE 8080

CMD GALAXY_RUN_ALL=1 ./run.sh --daemon && tail -f *.log
