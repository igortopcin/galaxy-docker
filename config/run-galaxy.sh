#!/bin/bash
cd $GALAXY_HOME

echo "$@" | grep -q -e '--run-condor'
RUN_CONDOR=$?
ARGS=`echo "$@" | sed 's/--run-condor//'`

JOB_CONF_XML_SAMPLE=./config/job_conf.xml.sample_basic

if [ $RUN_CONDOR -eq 0 ]; then
    JOB_CONF_XML_SAMPLE=./config/job_conf.xml.sample_condor
    /etc/init.d/condor start
fi

cp $JOB_CONF_XML_SAMPLE ./config/job_conf.xml

if [ ! -f "$GALAXY_DATA/shed_tool_conf.xml" ]; then
    cp config/shed_tool_conf.xml $GALAXY_DATA/shed_tool_conf.xml
fi

export GALAXY_RUN_ALL=1
./run.sh --daemon $ARGS || exit 1

tail -f *.log
