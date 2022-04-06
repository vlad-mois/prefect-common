#!/bin/bash

# Common run script to create appropriate supervisord.conf file.

supervisord_conf_src="/etc/supervisor/conf.d/conf.src.bak";
supervisord_conf_intermediate="/etc/supervisor/conf.d/conf.intermediate";
supervisord_conf_dst="/etc/supervisor/conf.d/supervisord.conf";

cp $supervisord_conf_src $supervisord_conf_intermediate;

function add_section() {
    local name="${1}"
    local command="${2}"

    echo "" >> $supervisord_conf_intermediate;
    echo "[program:$name]" >> $supervisord_conf_intermediate;
    echo "command=$command" >> $supervisord_conf_intermediate;
}

if [[ $RUN_HASURA == "true" ]]; then
    echo RUN_HASURA=$RUN_HASURA;
    add_section "hasura" "/start_1_hasura.sh";
fi

if [[ $RUN_GRAPHQL == "true" ]]; then
    echo RUN_GRAPHQL=$RUN_GRAPHQL;
    add_section "graphql" "/start_2_graphql.sh";
fi

if [[ $RUN_TOWEL == "true" ]]; then
    echo RUN_TOWEL=$RUN_TOWEL;
    add_section "towel" "/start_3_towel.sh";
fi

if [[ $RUN_APOLLO == "true" ]]; then
    echo RUN_APOLLO=$RUN_APOLLO;
    add_section "apollo" "/start_4_apollo.sh";
fi

if [[ $RUN_UI == "true" ]]; then
    echo RUN_UI=$RUN_UI;
    add_section "ui" "/start_5_ui.sh";
fi

if [[ $RUN_AGENTS == "true" ]]; then
    echo RUN_AGENTS=$RUN_AGENTS;
    echo PREFECT_AGENTS_COUNT=${PREFECT_AGENTS_COUNT:-1}
    for index in $(seq 1 ${PREFECT_AGENTS_COUNT:-1}); do
        add_section "agent_$index" "/start_6_agent.sh local-agent-$index";
    done
fi

cp $supervisord_conf_intermediate $supervisord_conf_dst;

echo "Starting supervisord with conf:";
printf '%b\n' "$(cat $supervisord_conf_dst)";
/usr/bin/supervisord
