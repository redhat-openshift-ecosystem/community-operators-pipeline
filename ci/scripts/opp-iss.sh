#!/bin/bash
set +o pipefail

# iss.sh  (Index Sync Sha)

OPP_PRODUCTION_INDEX_IMAGE_TAG=${2-"latest"}

OPP_THIS_REPO_BASE=${OPP_THIS_REPO_BASE-"https://github.com"}
OPP_THIS_REPO=${OPP_THIS_REPO-"redhat-openshift-ecosystem/community-operators-pipeline"}
OPP_THIS_BRANCH=${OPP_THIS_BRANCH-"main"}

OPP_IMAGE=${OPP_IMAGE-"quay.io/operator_testing/operator-test-playbooks:latest"}
OPP_CONTAINER_TOOL=${OPP_CONTAINER_TOOL-"docker"}
OPP_CONTAINER_OPT=${OPP_CONTAINER_OPT-"-it"}
OPP_NAME=${OPT_TEST_NAME-"op-sync-sha"}
OPP_CONAINER_RUN_DEFAULT_ARGS=${OPP_CONAINER_RUN_DEFAULT_ARGS-"--privileged --net host -e STORAGE_DRIVER=vfs -e BUILDAH_FORMAT=docker -e GODEBUG=x509ignoreCN=0"}
OPP_CONTAINER_RUN_EXTRA_ARGS=${OPP_CONTAINER_RUN_EXTRA_ARGS-""}
OPP_EXEC_USER=${OPP_EXEC_USER-""}
OPP_EXEC_USER_SECRETS=${OPP_EXEC_USER_SECRETS-""}
OPP_EXEC_BASE=${OPP_EXEC_BASE-"ansible-playbook -i localhost, -e ansible_connection=local upstream/local.yml -e run_upstream=true -e image_protocol='docker://'"}
### OPP_EXEC_EXTRA=${OPP_EXEC_EXTRA-"-e container_tool=podman --tags sync_index_sha"}
OPP_EXEC_EXTRA=${OPP_EXEC_EXTRA-"-e container_tool=podman --tags mirror_index"}
OPP_INDEX_POSTFIX=${OPP_INDEX_POSTFIX-"s"}
OPP_ANSIBLE_PULL_REPO=${OPP_ANSIBLE_PULL_REPO-"https://github.com/redhat-openshift-ecosystem/operator-test-playbooks"}
OPP_ANSIBLE_PULL_BRANCH=${OPP_ANSIBLE_PULL_BRANCH-"upstream-community"}
OPP_ANSIBLE_DEFAULT_ARGS=${OPP_ANSIBLE_DEFAULT_ARGS-"-i localhost, -e ansible_connection=local -e run_upstream=true -e run_remove_catalog_repo=false upstream/local.yml"}
IIB_INPUT_REGISTRY_USER=${IIB_INPUT_REGISTRY_USER-"mavala"}
IIB_OUTPUT_REGISTRY_USER=${IIB_OUTPUT_REGISTRY_USER-"redhat+iib_community"}
#$OPP_CONTAINER_TOOL rm -f $OPP_NAME > /dev/null 2>&1
OP_INFO_FILE_LOCATION=${OP_INFO_FILE_LOCATION-"/tmp/operator-test"}

OPP_RELEASE_INDEX_REGISTRY=${OPP_RELEASE_INDEX_REGISTRY-"quay.io"}
OPP_RELEASE_INDEX_ORGANIZATION=${OPP_RELEASE_INDEX_ORGANIZATION-"community-operators-pipeline"}
OPP_RELEASE_INDEX_NAME=${OPP_RELEASE_INDEX_NAME-"catalog"}
OPP_PRODUCTION_REGISTRY_NAMESPACE="$OPP_RELEASE_INDEX_REGISTRY/$OPP_RELEASE_INDEX_ORGANIZATION"
OPP_PRODUCTION_INDEX_IMAGE="$OPP_RELEASE_INDEX_REGISTRY/$OPP_RELEASE_INDEX_ORGANIZATION/$OPP_RELEASE_INDEX_NAME"
OPP_MIRROR_INDEX_REGISTRY=${OPP_MIRROR_INDEX_REGISTRY-"quay.io"}
OPP_MIRROR_INDEX_ORGANIZATION=${OPP_MIRROR_INDEX_ORGANIZATION-"community-operators-pipeline"}
OPP_MIRROR_INDEX_NAME=${OPP_MIRROR_INDEX_NAME-"catalog_prod"}
OPP_MIRROR_INDEX_IMAGE="$OPP_MIRROR_INDEX_REGISTRY/$OPP_MIRROR_INDEX_ORGANIZATION/$OPP_MIRROR_INDEX_NAME"

OPP_MIRROR_LATEST_TAG=${OPP_MIRROR_LATEST_TAG-"v4.6"}

[ -n "$OPP_MIRROR_INDEX_MULTIARCH_BASE" ] && OPP_MIRROR_INDEX_MULTIARCH_BASE_TAG=$(echo $OPP_MIRROR_INDEX_MULTIARCH_BASE | cut -d ':' -f 2) && OPP_MIRROR_INDEX_MULTIARCH_BASE=$(echo $OPP_MIRROR_INDEX_MULTIARCH_BASE | cut -d ':' -f 1)
[ "$OPP_MIRROR_INDEX_MULTIARCH_BASE_TAG" = "$OPP_MIRROR_INDEX_MULTIARCH_BASE" ] && OPP_MIRROR_INDEX_MULTIARCH_BASE_TAG=

echo "OPP_MIRROR_INDEX_MULTIARCH_BASE=$OPP_MIRROR_INDEX_MULTIARCH_BASE"
echo "OPP_MIRROR_INDEX_MULTIARCH_BASE_TAG=$OPP_MIRROR_INDEX_MULTIARCH_BASE_TAG"
echo "OPP_MULTIARCH_SUPPORTED_VERSIONS=$OPP_MULTIARCH_SUPPORTED_VERSIONS"

OPP_PRODUCTION_INDEX_IMAGE_TAG="$(echo $OPP_PRODUCTION_INDEX_IMAGE_TAG | cut -d '-' -f 1)"

# Handle OPP_MULTIARCH_SUPPORTED_VERSIONS
if [ -n "$OPP_MULTIARCH_SUPPORTED_VERSIONS" ];then
    if [ -z "$OPP_MIRROR_INDEX_MULTIARCH_BASE_TAG" ];then
      OPP_MIRROR_INDEX_MULTIARCH_BASE_TAG=$OPP_PRODUCTION_INDEX_IMAGE_TAG
      v_last=
      for v in $OPP_MULTIARCH_SUPPORTED_VERSIONS;do
          # echo "OPP_MULTIARCH_SUPPORTED_VERSIONS=[$OPP_MULTIARCH_SUPPORTED_VERSIONS] $v $OPP_MIRROR_INDEX_MULTIARCH_BASE_TAG"
          v_last=$v
          [ "$v" = "$OPP_MIRROR_INDEX_MULTIARCH_BASE_TAG" ] && break
      done
      OPP_MIRROR_INDEX_MULTIARCH_BASE_TAG=$v_last
    fi
    echo "OPP_MIRROR_INDEX_MULTIARCH_BASE_TAG=$OPP_MIRROR_INDEX_MULTIARCH_BASE_TAG"
fi
[ -n "$OPP_MIRROR_INDEX_MULTIARCH_BASE_TAG" ] || { echo "Multiarch image tag cound not be detected !!! ('$OPP_MIRROR_INDEX_MULTIARCH_BASE:$OPP_MIRROR_INDEX_MULTIARCH_BASE_TAG' OPP_MULTIARCH_SUPPORTED_VERSIONS=$OPP_MULTIARCH_SUPPORTED_VERSIONS)"; exit 1; }

function iib_install() {
    echo "Installing iib ..."
    set -o pipefail
    echo "Loging to registry.redhat.io ..."
    if [ -n "$IIB_INPUT_REGISTRY_TOKEN" ];then
      echo "$IIB_INPUT_REGISTRY_TOKEN" | $OPP_CONTAINER_TOOL login registry.redhat.io -u $IIB_INPUT_REGISTRY_USER --password-stdin || { echo "Problem to login to 'registry.redhat.io' !!!"; exit 1; }
      if [ -n "$IIB_OUTPUT_REGISTRY_TOKEN" ];then
        echo "$IIB_OUTPUT_REGISTRY_TOKEN" | $OPP_CONTAINER_TOOL login quay.io -u $IIB_OUTPUT_REGISTRY_USER --password-stdin || { echo "Problem to login to 'quay.io' !!!"; exit 1; }
      fi
    else
        echo "Variable \$IIB_INPUT_REGISTRY_TOKEN is not set or is empty !!!"
        exit 1
    fi

    ansible-pull -U $OPP_ANSIBLE_PULL_REPO -C $OPP_ANSIBLE_PULL_BRANCH $OPP_ANSIBLE_DEFAULT_ARGS -e run_prepare_catalog_repo_upstream=false --tags iib
    # -e iib_push_image="$IIB_PUSH_IMAGE" -e iib_push_registry="$(echo $IIB_PUSH_IMAGE | cut -d '/' -f 1)"
    if [[ $? -eq 0 ]];then
        $OPP_CONTAINER_TOOL cp $HOME/.docker/config.json iib_iib-worker_1:/root/.docker/config.json.template || exit 1
        echo -e "\n=================================================================================="
        echo -e "IIB was installed successfully !!!"
        echo -e "==================================================================================\n"
    else
        echo "Problem installing iib !!!"
        exit 1
    fi
    set +o pipefail
}
OPP_EXEC_USER="-e catalog_repo=$OPP_THIS_REPO_BASE/$OPP_THIS_REPO -e catalog_repo_branch=$OPP_THIS_BRANCH"
OPP_EXEC_USER="$OPP_EXEC_USER -e bundle_index_image_version=$OPP_PRODUCTION_INDEX_IMAGE_TAG -e sis_index_image_input=$OPP_PRODUCTION_INDEX_IMAGE:$OPP_PRODUCTION_INDEX_IMAGE_TAG -e sis_index_image_output=$OPP_PRODUCTION_INDEX_IMAGE:${2}${OPP_INDEX_POSTFIX} -e op_base_name=operators"
OPP_EXEC_USER_SECRETS="-e quay_api_token=$REGISTRY_RELEASE_API_TOKEN"

[ -n "$IIB_INPUT_REGISTRY_USER" ] && OPP_EXEC_USER="$OPP_EXEC_USER -e quay_arch_input_user=$IIB_INPUT_REGISTRY_USER -e quay_arch_input_host=$(echo $OPP_MIRROR_INDEX_MULTIARCH_BASE | cut -d '/' -f 1)"
[ -n "$IIB_INPUT_REGISTRY_TOKEN" ] && OPP_EXEC_USER_SECRETS="$OPP_EXEC_USER_SECRETS -e quay_arch_input_password=\"$IIB_INPUT_REGISTRY_TOKEN\""

if [ -f "$OP_INFO_FILE_LOCATION/op_info.yaml" ]; then OPP_EXEC_USER="$OPP_EXEC_USER -e operator_info_file=$OP_INFO_FILE_LOCATION/op_info.yaml"; fi

OPP_EXEC_USER="$OPP_EXEC_USER -e automatic_cluster_version_label=true"

if [ "$1" = "openshift" ];then
  [ "$OPP_MIRROR_INDEX_MULTIARCH_BASE" != "" ] && OPP_EXEC_USER="$OPP_EXEC_USER -e mirror_multiarch_image=$OPP_MIRROR_INDEX_MULTIARCH_BASE:$OPP_MIRROR_INDEX_MULTIARCH_BASE_TAG -e mirror_apply=true -e bundle_index_image=$OPP_PRODUCTION_INDEX_IMAGE:${2}"
  [ "$OPP_MIRROR_LATEST_TAG" != "${OPP_PRODUCTION_INDEX_IMAGE_TAG}" ] && OPP_EXEC_USER_SECRETS="$OPP_EXEC_USER_SECRETS -e mirror_index_images=\"$OPP_MIRROR_INDEX_IMAGE:${OPP_PRODUCTION_INDEX_IMAGE_TAG}|$OPP_REGISTRY_MIRROR_USER|$REGISTRY_MIRROR_PW|$OPP_MIRROR_INDEX_MULTIARCH_POSTFIX\""
  [ "$OPP_MIRROR_LATEST_TAG" == "${OPP_PRODUCTION_INDEX_IMAGE_TAG}" ] && OPP_EXEC_USER_SECRETS="$OPP_EXEC_USER_SECRETS -e mirror_index_images=\"$OPP_MIRROR_INDEX_IMAGE:${OPP_PRODUCTION_INDEX_IMAGE_TAG}|$OPP_REGISTRY_MIRROR_USER|$REGISTRY_MIRROR_PW|$OPP_MIRROR_INDEX_MULTIARCH_POSTFIX|$OPP_MIRROR_INDEX_IMAGE:latest\""
  ### OPP_EXEC_EXTRA="$OPP_EXEC_EXTRA,mirror_index"
fi

$OPP_CONTAINER_TOOL run -d --rm $OPP_CONTAINER_OPT --name $OPP_NAME $OPP_CONAINER_RUN_DEFAULT_ARGS $OPP_CONTAINER_RUN_EXTRA_ARGS $OPP_IMAGE
[ "$1" == "openshift" ] && iib_install

echo "$OPP_EXEC_BASE $OPP_EXEC_EXTRA $OPP_EXEC_USER"
$OPP_CONTAINER_TOOL exec $OPP_CONTAINER_OPT $OPP_NAME /bin/bash -c "$OPP_EXEC_BASE $OPP_EXEC_EXTRA $OPP_EXEC_USER $OPP_EXEC_USER_SECRETS"
