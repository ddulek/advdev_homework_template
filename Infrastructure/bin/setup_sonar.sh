#!/bin/bash
# Setup Sonarqube Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Sonarqube in project $GUID-sonarqube"

# Code to set up the SonarQube project.
# Ideally just calls a template
# oc new-app -f ../templates/sonarqube.yaml --param .....

# To be Implemented by Student
oc new-app -n ${GUID}-sonarqube --template=postgresql-persistent --param POSTGRESQL_USER=sonar --param POSTGRESQL_PASSWORD=sonar --param POSTGRESQL_DATABASE=sonar --param VOLUME_CAPACITY=4Gi --labels=app=sonarqube_db

oc rollout status dc/postgresql -n ${GUID}-sonarqube -w

oc new-app -n ${GUID}-sonarqube --docker-image=wkulhanek/sonarqube:6.7.4 --env=SONARQUBE_JDBC_USERNAME=sonar --env=SONARQUBE_JDBC_PASSWORD=sonar --env=SONARQUBE_JDBC_URL=jdbc:postgresql://postgresql/sonar --labels=app=sonarqube

oc scale -n ${GUID}-sonarqube dc/sonarqube --replicas=0
oc rollout pause -n ${GUID}-sonarqube dc/sonarqube

oc expose service -n ${GUID}-sonarqube sonarqube
oc volume -n ${GUID}-sonarqube dc/sonarqube --add --overwrite --name=sonarqube-volume-1 --mount-path=/opt/sonarqube/data/ --type persistentVolumeClaim --claim-name=sonarqube-pvc --claim-size=4Gi

oc set resources -n ${GUID}-sonarqube dc sonarqube --limits=memory=3Gi,cpu=2 --requests=memory=1.5Gi,cpu=1
oc patch -n ${GUID}-sonarqube dc sonarqube --patch='{ "spec": { "strategy": { "type": "Recreate" }}}'

oc set probe -n ${GUID}-sonarqube dc/sonarqube --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
oc set probe -n ${GUID}-sonarqube dc/sonarqube --readiness --failure-threshold 3 --initial-delay-seconds 20 --get-url=http://:9000/about

oc scale -n ${GUID}-sonarqube dc/sonarqube --replicas=1
oc rollout -n ${GUID}-sonarqube resume dc/sonarqube
