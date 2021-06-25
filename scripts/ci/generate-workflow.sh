#!/usr/bin/env bash
set -e
#rm -rf /tmp/community-operators
#git clone https://github.com/operator-framework/community-operators.git /tmp/community-operators
BASE_LOCATION=$(pwd)
ANSIBLE_STDOUT_CALLBACK=yaml ansible-pull -U https://github.com/operator-framework/operator-test-playbooks -C master -i localhost, upstream/set-pipeline-workflow.yml -e ansible_connection=local -e workflow_templates_path=/tmp/community-operators/scripts/template/workflow/ -e workflow_config_path=$BASE_LOCATION -vv

