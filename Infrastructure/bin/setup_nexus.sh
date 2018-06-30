#!/bin/bash
# Setup Nexus Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Nexus in project $GUID-nexus"

# Code to set up the Nexus. It will need to
# * Create Nexus
# * Set the right options for the Nexus Deployment Config
# * Load Nexus with the right repos
# * Configure Nexus as a docker registry
# Hint: Make sure to wait until Nexus if fully up and running
#       before configuring nexus with repositories.
#       You could use the following code:
# while : ; do
#   echo "Checking if Nexus is Ready..."
#   oc get pod -n ${GUID}-nexus|grep '\-2\-'|grep -v deploy|grep "1/1"
#   [[ "$?" == "1" ]] || break
#   echo "...no. Sleeping 10 seconds."
#   sleep 10
# done

# Ideally just calls a template
# oc new-app -f ../templates/nexus.yaml --param .....

# To be Implemented by Student
oc new-app -n ${GUID}-nexus sonatype/nexus3:latest
oc rollout pause -n ${GUID}-nexus dc/nexus3

oc volume -n ${GUID}-nexus dc/nexus3 --add --name=nexus3-volume-1 --overwrite --claim-size=2Gi
oc set resources -n ${GUID}-nexus dc nexus3 --limits=memory=2Gi --requests=memory=1Gi

oc patch dc/nexus3 -n ${GUID}-nexus --patch '{"spec":{"strategy":{"type":"Recreate"}}}'


oc set probe dc/nexus3 -n ${GUID}-nexus --liveness --failure-threshold 3 --initial-delay-seconds 60 -- echo ok
oc set probe dc/nexus3 -n ${GUID}-nexus --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8081/repository/maven-public/

oc expose -n ${GUID}-nexus svc nexus3

oc rollout resume -n ${GUID}-nexus dc/nexus3
oc expose -n ${GUID}-nexus dc nexus3 --port=5000 --name=nexus-registry
oc create -n ${GUID}-nexus route edge nexus-registry --service=nexus-registry --port=5000

oc rollout status -n ${GUID}-nexus dc/nexus3 --watch
sleep 10

curl -o setup_nexus3.sh -s https://raw.githubusercontent.com/wkulhanek/ocp_advanced_development_resources/master/nexus/setup_nexus3.sh
chmod +x setup_nexus3.sh
./setup_nexus3.sh admin admin123 http://$(oc get route -n ${GUID}-nexus nexus3 --template='{{ .spec.host }}')
rm setup_nexus3.sh
