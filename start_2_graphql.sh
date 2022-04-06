#!/bin/bash

sleep 5;

cd /prefect-server \
  && bash -c 'prefect-server database upgrade -y \
              && python src/prefect_server/services/graphql/server.py'
