############################################################
# Dockerfile to build Medical Imaging Galaxy
# Based on Ubuntu 14.04
############################################################

# Set the base image to Ubuntu
FROM ubuntu:trusty

RUN apt-get update && apt-get install -y tar less git mercurial curl vim wget unzip netcat software-properties-common python-pip python-virtualenv
RUN wget https://bitbucket.org/pypa/setuptools/downloads/ez_setup.py -O - | python

# Add condor to apt-sources
RUN echo "deb [arch=amd64] http://research.cs.wisc.edu/htcondor/debian/development/ wheezy contrib" >> /etc/apt/sources.list && \
    echo "deb [arch=amd64] http://research.cs.wisc.edu/htcondor/debian/stable/ wheezy contrib" >> /etc/apt/sources.list && \
    wget -qO - http://research.cs.wisc.edu/htcondor/debian/HTCondor-Release.gpg.key | apt-key add - && \
    apt-get update

RUN apt-get install -y condor

# Make sure we stop condor - it will be started just before we start galaxy server
RUN /etc/init.d/condor stop

# Configure condor submitter
ADD ./config/condor_config.local /etc/condor/condor_config.local

ENV _CONDOR_CONDOR_HOST=condormanager.migcloud.org \
    _CONDOR_COLLECTOR_NAME=medsquare \
    _CONDOR_CONDOR_ADMIN=dev@mig.ime.usp.br

ENV GALAXY_HOME=/usr/local/galaxy
ADD galaxy $GALAXY_HOME

# Expose Galaxy data dir as a mountable volume
ENV GALAXY_DATA=/data
VOLUME $GALAXY_DATA

WORKDIR $GALAXY_HOME

RUN apt-get install -y python-dev libpq-dev
ENV GALAXY_VIRTUAL_ENV=/usr/local/galaxy/galaxy_venv
ADD config/requirements-mig.txt requirements-mig.txt
RUN ./scripts/common_startup.sh
RUN $GALAXY_VIRTUAL_ENV/bin/pip install -r requirements-mig.txt

ADD config/galaxy.ini config/galaxy.ini
ADD config/job_conf.xml.sample_basic config/job_conf.xml
ADD config/job_conf.xml.sample_basic config/job_conf.xml.sample_basic
ADD config/job_conf.xml.sample_condor config/job_conf.xml.sample_condor
ADD config/shed_tool_conf.xml config/shed_tool_conf.xml
ADD config/tool_sheds_conf.xml config/tool_sheds_conf.xml
ADD config/run-galaxy.sh run-galaxy.sh

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

ENTRYPOINT ["./run-galaxy.sh"]
