#!/bin/bash

sleep 15;

if [[ -z ${APOLLO_API_PORT} ]]
then
    APOLLO_API_PORT="4200"
    echo "Missing APOLLO_API_PORT environment variable.  Using default: $APOLLO_API_PORT"
fi

prefect backend server
prefect server create-tenant -n default \
        || echo "Got exception while tenant creation. It probably already exists." >&2

prefect agent local start --no-hostname-label --name $1
