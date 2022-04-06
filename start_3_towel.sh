#!/bin/bash

sleep 10;

cd /prefect-server \
  && python src/prefect_server/services/towel/__main__.py
