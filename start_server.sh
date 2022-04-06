#!/usr/bin/env bash

if [[ -z ${PREFECT_UI_PORT} ]]
then
    echo "Missing PREFECT_UI_PORT environment variable.  Using default"
    PREFECT_UI_PORT="8080"
fi

export nginx_conf=/etc/nginx/conf.d/default.conf
export nginx_conf_bak=$HOME/nginx.conf.d.default.conf.bak
if [ ! -f $nginx_conf_bak ]
then
    echo "Backup $nginx_conf -> $nginx_conf_bak"
    cp -f $nginx_conf $nginx_conf_bak
fi
cp -f $nginx_conf_bak $nginx_conf
sed -i "s,listen 8080,listen $PREFECT_UI_PORT," $nginx_conf

# Set default prefect_ui_settings if
# env vars not present
if [[ -z ${PREFECT_SERVER__APOLLO_URL} ]]
then
    echo "Missing the PREFECT_SERVER__APOLLO_URL environment variable.  Using default"
    PREFECT_SERVER__APOLLO_URL="http://localhost:4200/graphql"
fi

if [[ -n $PREFECT_UI_APOLLO_RELATIVE_PATH ]]
then
    echo "PREFECT_UI_APOLLO_RELATIVE_PATH=$PREFECT_UI_APOLLO_RELATIVE_PATH"
    sed -i "s,# Redirect section,location /$PREFECT_UI_APOLLO_RELATIVE_PATH { proxy_pass http://localhost:$APOLLO_API_PORT/graphql; }," $nginx_conf
fi

if [[ -z ${PREFECT_SERVER__BASE_URL} ]]
then
    echo "Missing the PREFECT_SERVER__BASE_URL environment variable.  Using default"
    PREFECT_SERVER__BASE_URL="/"
fi

sed -i "s,PREFECT_SERVER__APOLLO_URL,$PREFECT_SERVER__APOLLO_URL," /var/www/settings.json
sed -i "s,PREFECT_SERVER__APOLLO_URL,$PREFECT_SERVER__APOLLO_URL," /var/www/settings.json
sed -i "s,PREFECT_SERVER__BASE_URL,$PREFECT_SERVER__BASE_URL," /var/www/settings.json

echo "👾👾👾 UI running at localhost:${PREFECT_UI_PORT} 👾👾👾"

nginx -g "daemon off;"
