#!/bin/bash
set +o pipefail

OPP_FILES_TO_COPY="ci/root/categories.json ci/root/upstream.Dockerfile"
OPP_CI_SCRIPTS_DIR="ci/prow"
OPP_FILES_TO_COPY_CI_SCRIPTS="ci/legacy/scripts/ci/openshift-deploy-core.sh ci/legacy/scripts/ci/openshift-deploy.sh ci/legacy/scripts/ci/Dockerfile.ci-operator"

OPP_ANSIBLE_PULL_REPO=${OPP_ANSIBLE_PULL_REPO-"https://github.com/redhat-openshift-ecosystem/operator-test-playbooks"}
OPP_ANSIBLE_PULL_BRANCH=${OPP_ANSIBLE_PULL_BRANCH-"upstream-community"}

OPP_INPUT_REPO=${OPP_INPUT_REPO-"https://github.com/redhat-openshift-ecosystem/community-operators-pipeline"}
OPP_INPUT_BRANCH=${OPP_INPUT_BRANCH-"ci/latest"}
OPP_CONTAINER_TOOL=${OPP_CONTAINER_TOOL-docker}
OPP_ANSIBLE_ARGS="-i localhost, -e ansible_connection=local upstream/local-pipeline-update.yml"
OPP_ANSIBLE_EXTRA_ARGS=""

OPP_INDEX_IMAGE_POSTFIX=${OPP_INDEX_IMAGE_POSTFIX-"s"}

[ "$1" = "reset" ] && OPP_ANSIBLE_EXTRA_ARGS="-e empty_index=quay.io/operator_testing/index_empty" && shift

OPP_TMP_DIR="/tmp/opp-update"

if [ -n "$1" ];then
    cd ci
    if [ ! -f pipeline-config-${CLUSTER_TYPE}.yaml ]; then
        mv pipeline-config.yaml ci/pipeline-config-${CLUSTER_TYPE}.yaml
        ln -sfn pipeline-config-${CLUSTER_TYPE}.yaml pipeline-config.yaml
    fi
    cd -
    CLUSTER_TYPE="-$CLUSTER_TYPE"
fi

[ -d $OPP_TMP_DIR ] && rm -rf $OPP_TMP_DIR
mkdir -p $OPP_TMP_DIR
git clone $OPP_INPUT_REPO --branch $OPP_INPUT_BRANCH $OPP_TMP_DIR/opp-input

ANSIBLE_STDOUT_CALLBACK=yaml ansible-pull -U $OPP_ANSIBLE_PULL_REPO -C $OPP_ANSIBLE_PULL_BRANCH $OPP_ANSIBLE_ARGS \
-e pipeline_config_name="pipeline-config${CLUSTER_TYPE}.yaml" \
-e workflow_config_path="$PWD/ci" \
-e workflow_templates_path="$OPP_TMP_DIR/opp-input/ci/templates/workflow" \
-e workflow_output_path="$PWD/.github/workflows" \
-e quay_api_token=$REGISTRY_RELEASE_API_TOKEN \
-e container_tool=$OPP_CONTAINER_TOOL \
-e pu_postfix=$OPP_INDEX_IMAGE_POSTFIX \
$OPP_ANSIBLE_EXTRA_ARGS || { echo "Problem running upgrade ansilbe script"; exit 1; }

for f in $OPP_FILES_TO_COPY;do
    echo "Doing 'cp $OPP_TMP_DIR/opp-input/$f $PWD/$(basename $f)'"
    cp $OPP_TMP_DIR/opp-input/$f $PWD/$(basename $f)
done

[ -d $PWD/$OPP_CI_SCRIPTS_DIR ] || mkdir -p $PWD/$OPP_CI_SCRIPTS_DIR

yq --version
MY_ANSIBLE_PULL_REPO=$(yq '.pipeline.playbooks.repo' $PWD/ci/pipeline-config${CLUSTER_TYPE}.yaml -r )
MY_ANSIBLE_PULL_BRANCH=$(yq '.pipeline.playbooks.branch' $PWD/ci/pipeline-config${CLUSTER_TYPE}.yaml -r)

MY_ANSIBLE_PULL_REPO=${MY_ANSIBLE_PULL_REPO//\//\\\\\\/}
MY_ANSIBLE_PULL_BRANCH=${MY_ANSIBLE_PULL_BRANCH//\//\\\\\\/}

echo "MY_ANSIBLE_PULL_REPO=$MY_ANSIBLE_PULL_REPO"
echo "MY_ANSIBLE_PULL_BRANCH=$MY_ANSIBLE_PULL_BRANCH"

for f in $OPP_FILES_TO_COPY_CI_SCRIPTS;do
    echo "Doing 'cp $OPP_TMP_DIR/opp-input/$OPP_CI_SCRIPTS_DIR/$f $PWD/$OPP_CI_SCRIPTS_DIR/$(basename $f)'"
    cp $OPP_TMP_DIR/opp-input/$f $PWD/$OPP_CI_SCRIPTS_DIR/$(basename $f)
    echo "1"
    sed -i 's/^PLAYBOOK_REPO=.*/PLAYBOOK_REPO='"$MY_ANSIBLE_PULL_REPO"'/g' $PWD/$OPP_CI_SCRIPTS_DIR/$(basename $f)
    echo "2"
    sed -i 's/^PLAYBOOK_REPO_BRANCH=.*/PLAYBOOK_REPO_BRANCH='"$MY_ANSIBLE_PULL_BRANCH"'/g' $PWD/$OPP_CI_SCRIPTS_DIR/$(basename $f)
done

rm -rf $PWD/scripts
mkdir -p $PWD/scripts
ln -sfn ../$OPP_CI_SCRIPTS_DIR scripts/ci

######## Gen empty index ###############################
#
#/tmp/operator-test/bin/opm index add --bundles quay.io/operator_testing/aqua:v0.0.1 --tag quay.io/operator_testing/index_empty:latest --mode semver -p none
#podman login quay.io -u mavala
#podman push quay.io/operator_testing/index_empty:latest
#/tmp/operator-test/bin/opm index rm -o aqua --from-index quay.io/operator_testing/index_empty:latest --tag quay.io/operator_testing/index_empty:latest -p none
#podman push quay.io/operator_testing/index_empty:latest
#
########################################################
