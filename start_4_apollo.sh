#!/bin/bash

sleep 10;

# post-start.sh just wait for grahpql response by $PREFECT_API_HEALTH_URL.
cd /apollo \
  && bash -c "./post-start.sh && npm run serve"
