#!/bin/bash

sleep 15;

# Allows to make chenges between runs.
if [ -d /var/www ]; then rm -r /var/www; fi
cp -r /var/www.bak /var/www

# intercept.sh just run start_server.sh
# start_server.sh make some /var/www/settings.json substitutions and run nginx.
/intercept.sh
