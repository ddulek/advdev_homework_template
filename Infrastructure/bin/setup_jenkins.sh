#!/bin/bash
# Setup Jenkins Project
if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "  $0 GUID REPO CLUSTER"
    echo "  Example: $0 wkha https://github.com/wkulhanek/ParksMap na39.openshift.opentlc.com"
    exit 1
fi

GUID=$1
REPO=$2
CLUSTER=$3
echo "Setting up Jenkins in project ${GUID}-jenkins from Git Repo ${REPO} for Cluster ${CLUSTER}"

# Code to set up the Jenkins project to execute the
# three pipelines.
# This will need to also build the custom Maven Slave Pod
# Image to be used in the pipelines.
# Finally the script needs to create three OpenShift Build
# Configurations in the Jenkins Project to build the
# three micro services. Expected name of the build configs:
# * mlbparks-pipeline
# * nationalparks-pipeline
# * parksmap-pipeline
# The build configurations need to have two environment variables to be passed to the Pipeline:
# * GUID: the GUID used in all the projects
# * CLUSTER: the base url of the cluster used (e.g. na39.openshift.opentlc.com)

# To be Implemented by Student
oc new-app jenkins-persistent --param ENABLE_OAUTH=true --param MEMORY_LIMIT=2Gi --param VOLUME_CAPACITY=4Gi -n ${GUID}-jenkins
oc set resources dc/jenkins --limits=cpu=1 --requests=memory=2Gi,cpu=1 -n ${GUID}-jenkins
oc rollout status dc/jenkins -n ${GUID}-jenkins -w

cat <<ENDL | oc new-build -n ${GUID}-jenkins --name jenkins-slave-appdev -D -
FROM docker.io/openshift/jenkins-slave-maven-centos7:v3.9
USER root
RUN yum -y install skopeo apb &&     yum clean all
USER 1001
ENDL


oc new-build -n ${GUID}-jenkins https://github.com/ddulek/advdev_homework_template.git --context-dir=MLBParks --name mlbparks-pipeline
oc new-build -n ${GUID}-jenkins https://github.com/ddulek/advdev_homework_template.git --context-dir=ParksMap --name parksmap-pipeline
oc new-build -n ${GUID}-jenkins https://github.com/ddulek/advdev_homework_template.git --context-dir=Nationalparks --name nationalparks-pipeline

