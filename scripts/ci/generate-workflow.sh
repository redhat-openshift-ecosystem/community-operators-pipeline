#!/usr/bin/env bash
set -e
cd /tmp
git clone https://github.com/operator-framework/community-operators.git
ANSIBLE_STDOUT_CALLBACK=yaml ansible-pull -U https://github.com/operator-framework/operator-test-playbooks -C master -i localhost, set-pipeline-workflow.yml -e workflow_templates_path=/tmp/community-operators/scripts/template/workflow/ -e workflow_config_path=./ci -vv

