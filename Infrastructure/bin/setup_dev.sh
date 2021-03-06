#!/bin/bash
# Setup Development Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Parks Development Environment in project ${GUID}-parks-dev"

# Code to set up the parks development project.

# To be Implemented by Student
oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n $GUID-parks-dev
oc create -f Infrastructure/templates/mongodb.yaml -n $GUID-parks-dev
