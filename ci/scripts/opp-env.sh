#!/bin/bash
# OPerator Pipeline (OPP) env script (opp-env.sh)

set -e
declare -A KIND_SUPPORT_TABLE=(["1.26"]="3" ["1.25"]="8" ["1.24"]="12" ["1.23"]="17" ["1.22"]="17" ["1.21"]="14")
KIND_MIN_SUPPORTED=1.18
KIND_MAX_SUPPORTED=1.25 # DO NOT FORGET TO CHANGE WHEN CHANGING ^
export INPUT_ENV_SCRIPT="/tmp/opp-env-vars"
OPP_ALLOW_CI_CHANGES=${OPP_ALLOW_CI_CHANGES-0}
OPP_ALLOW_FORCE_RELEASE=${OPP_ALLOW_FORCE_RELEASE-0}
OPP_TEST_READY=${OPP_TEST_READY-1}
OPP_RELEASE_READY=${OPP_RELEASE_READY-0}
OPP_OP_DELETE=${OPP_OP_DELETE-0}
OPP_PR_AUTHOR=${OPP_PR_AUTHOR-""}
DELETE_APPREG=${DELETE_APPREG-0}
OPRT=${OPRT-0}
OPP_THIS_REPO=${OPP_THIS_REPO-"redhat-openshift-ecosystem/community-operators-pipeline"}
OPP_THIS_BRANCH=${OPP_THIS_BRANCH-"main"}


OPP_CURRENT_PROJECT_DOC=${OPP_CURRENT_PROJECT_DOC-"https://operator-framework.github.io/community-operators"}

OPP_PRODUCTION_TYPE=${OPP_PRODUCTION_TYPE-"ocp"}
OPP_OPERATORS_DIR=${OPP_OPERATORS_DIR-"operators"}
OPP_REVIEWERS_ENABLED=${OPP_REVIEWERS_ENABLED-1}
OPP_INSTALLATION_SKIPED=${OPP_INSTALLATION_SKIPED-1}
OPP_INSTALLATION_SKIP_FOUND=${OPP_INSTALLATION_SKIP_FOUND-0}

OPP_CHANGES_GITHUB=0
OPP_CHANGES_CI=0
OPP_CHANGES_DOCS=0
OPP_CHANGES_IN_OPERATORS_DIR=0
OPP_CHANGES_STREAM_UPSTREAM=0
OPP_CI_YAML_CHANGED=0
OPP_CI_YAML_ONLY=0
OPP_CI_YAML_MODIFIED=0
OPP_CHANGES_PACKAGE_FILE=0
OPP_ALLOW_SERIOUS_CHANGES=0
OPP_IS_OPERATOR=0
OPP_IS_NEW_OPERATOR=0
OPP_PR_TITLE=
OPP_AUTHORIZED_CHANGES=0
OPP_REVIEVERS=""
OPP_CHANGES_DOCKERFILE=0
OPP_AUTO_PACKAGEMANIFEST_CLUSTER_VERSION_LABEL=0

# Error codes:
#   [1] overwrite and recreate labels set at same time
#   [2] both streams set
#   [3] non opearator files changed in directories : .github, docs, ...
#   [4] ci.yaml
#   [5] multiple operator changed
#   [6] Old version were changed and recreate label is not set
#   [7] Single file modification for ci.yaml allowed only
#   [10] Inform users about possibility to add reviewers
OPP_ERROR_CODE=0

OPP_VER_OVERWRITE=${OPP_VER_OVERWRITE-0}
OPP_RECREATE=${OPP_RECREATE-0}

OPP_SET_LABEL_OPERATOR_VERSION_OVERWRITE=0
OPP_SET_LABEL_OPERATOR_RECREATE=0
OPP_IS_MODIFIED=0
OPP_MODIFIED_CSVS=
OPP_UPDATEGRAPH=1
OPP_CI_YAML_UNSUPPORTED_FIELDS="addAssignees useAssigneeGroups assigneeGroups skipKeywords"

echo "OPP_ADDED_MODIFIED_FILES=$OPP_ADDED_MODIFIED_FILES"
echo "OPP_MODIFIED_FILES=$OPP_MODIFIED_FILES"
echo "OPP_RENAMED_FILES=$OPP_RENAMED_FILES"
echo "OPP_REMOVED_FILES=$OPP_REMOVED_FILES"
echo "OPP_LABELS=$OPP_LABELS"

echo "opp_error_code=$OPP_ERROR_CODE" >> $GITHUB_OUTPUT
echo "opp_recreate=${OPP_RECREATE}" >> $GITHUB_OUTPUT
echo "opp_auto_packagemanifest_cluster_version_label=$OPP_AUTO_PACKAGEMANIFEST_CLUSTER_VERSION_LABEL" >> $GITHUB_OUTPUT


for l in $(echo $OPP_LABELS);do
  echo "Checking label '$l' ..."
  [[ "$l" = "allow/ci-changes" ]] && export OPP_ALLOW_CI_CHANGES=1
  [[ "$l" = "allow/force-release" ]] && export OPP_ALLOW_FORCE_RELEASE=1
  [[ "$l" = "allow/operator-version-overwrite" ]] && export OPP_VER_OVERWRITE=1
  [[ "$l" = "allow/operator-recreate" ]] && export OPP_OP_DELETE=1 && export OPP_RECREATE=1
  [[ "$l" = "allow/serious-changes-to-existing" ]] && export OPP_ALLOW_SERIOUS_CHANGES=1

done
echo "opp_recreate=${OPP_RECREATE}" >> $GITHUB_OUTPUT

[[ $OPP_VER_OVERWRITE -eq 1 ]] && [[ $OPP_RECREATE -eq 1 ]] && { echo "Labels 'allow/operator-version-overwrite' and 'allow/operator-recreate' is set. Only one label can be set !!! Exiting ..." ; echo "opp_error_code=1" >> $GITHUB_OUTPUT; exit 1; }

OPP_CHANGES_OPERATOR=
OPP_CHANGES_OPERATOR_VERSIONS_MODIFIED=
OPP_CHANGES_OPERATOR_VERSIONS_REMOVED=

echo "opp_set_label_operator_version_overwrite=$OPP_SET_LABEL_OPERATOR_VERSION_OVERWRITE" >> $GITHUB_OUTPUT
echo "opp_set_label_operator_recreate=$OPP_SET_LABEL_OPERATOR_RECREATE" >> $GITHUB_OUTPUT
echo "opp_is_modified=$OPP_IS_MODIFIED" >> $GITHUB_OUTPUT
echo "opp_modified_csvs=$OPP_MODIFIED_CSVS" >> $GITHUB_OUTPUT
echo "opp_allow_serious_changes=$OPP_ALLOW_SERIOUS_CHANGES" >> $GITHUB_OUTPUT
echo "opp_is_new_operatror=${OPP_IS_NEW_OPERATOR}" >> $GITHUB_OUTPUT
echo "opp_pr_title=${OPP_PR_TITLE}" >> $GITHUB_OUTPUT
echo "opp_update_graph=${OPP_UPDATEGRAPH}" >> $GITHUB_OUTPUT
echo "opp_authorized_changes=${OPP_AUTHORIZED_CHANGES}" >> $GITHUB_OUTPUT
echo "opp_changed_ci_yaml=${OPP_CI_YAML_CHANGED}" >> $GITHUB_OUTPUT
echo "opp_ver_overwrite=${OPP_VER_OVERWRITE}" >> $GITHUB_OUTPUT


[ -z $OPP_LABELS ] && [[ $OPP_PROD -eq 1 ]] && OPP_ALLOW_CI_CHANGES=1

if [[ $OPP_ALLOW_CI_CHANGES -eq 1 ]] && [[ $OPP_PROD -eq 1 ]];then
  echo "opp_release_ready=$OPP_ALLOW_FORCE_RELEASE" >> $GITHUB_OUTPUT
  echo "CI changes detected. Continue doing release ..."
  exit 0
fi

if [[ $OPP_ALLOW_CI_CHANGES -eq 1 ]] && [[ $OPP_PROD -eq 0 ]];then
  echo "opp_test_ready=0" >> $GITHUB_OUTPUT
  echo "CI changes detected. No testing ..."
  exit 0
fi

# Handle removed files
if [ -n "$OPP_REMOVED_FILES" ];then

  # Some files are removed
  # TODO : OPP_CHANGES_OPERATOR_VERSIONS_REMOVED
  FILES=
  for sf in ${OPP_REMOVED_FILES}; do
    echo $sf
    # Check if .github/ dir is modified
    [[ $sf == .github* ]] && OPP_CHANGES_GITHUB=1 && continue
    [[ $sf == scripts* ]] && OPP_CHANGES_CI=1 && continue
    [[ $sf == ci* ]] && OPP_CHANGES_CI=1 && continue
    [[ $sf == docs* ]] && OPP_CHANGES_DOCS=1 && continue
    [[ $sf == operators* ]] ||  { echo "Not allowed changes outside operators directory. Affected file : '$sf' !!! Exiting ..."; exit 1; }
    [[ $sf == *Dockerfile* ]] && OPP_CHANGES_DOCKERFILE=1 && continue
    [[ $sf == operators* ]] && OPP_CHANGES_IN_OPERATORS_DIR=1
    # [[ $sf == community-operators* ]] && OPP_CHANGES_IN_OPERATORS_DIR=1
    # [[ $sf == upstream-community-operators* ]] && OPP_CHANGES_STREAM_UPSTREAM=1
    [[ $sf == *package.yaml ]] && OPP_CHANGES_PACKAGE_FILE=1 && continue
    [[ $sf == *ci.yaml ]] && { OPP_CI_YAML_CHANGED=1; continue; }
    # [[ $OPP_CHANGES_IN_OPERATORS_DIR -eq 0 ]] && [[ $OPP_CHANGES_STREAM_UPSTREAM -eq 0 ]] && { echo "No changes 'community-operators' or 'upstream-community-operators' !!! Exiting ..."; OPP_RELEASE_READY=0; }

    FILES="$FILES $(echo $sf | cut -d '/' -f 1-3)"
    # Check if outdside of "community-operators" and "upstream-community-operators"
  done

  [ -n "$FILES" ] && OPP_IS_OPERATOR=1

  # Handle removed only files
  if [ ! -n "$OPP_ADDED_MODIFIED_FILES" ];then
    # check if only ci.yaml was removed
    OPP_RELEASE_READY=1


    # [[ $OPP_CHANGES_IN_OPERATORS_DIR -eq 1 ]] && OPP_OPERATORS_DIR="community-operators"
    # [[ $OPP_CHANGES_STREAM_UPSTREAM -eq 1 ]] && OPP_OPERATORS_DIR="upstream-community-operators"

    VERSIONS=$(echo -e "${FILES// /\\n}" | uniq | sort -r)
    LATEST="$(echo -e $VERSIONS | cut -d ' ' -f 1)"
    OPP_OPERATOR_NAME=$(echo $LATEST | cut -d '/' -f 2)
    OPP_OPERATOR_VERSION=$(echo $LATEST | cut -d '/' -f 3)

    OPP_TEST_READY=0

    # [[ $OPP_CHANGES_IN_OPERATORS_DIR -eq 1 ]] && [[ $OPP_CHANGES_STREAM_UPSTREAM -eq 1 ]] && { echo "Changes in both 'community-operators' and 'upstream-community-operators' dirs !!! Exiting ..."; echo "opp_error_code=2" >> $GITHUB_OUTPUT; exit 1; }

    echo "opp_test_ready=${OPP_TEST_READY}" >> $GITHUB_OUTPUT
    echo "opp_release_ready=${OPP_RELEASE_READY}" >> $GITHUB_OUTPUT
    echo "opp_production_type=${OPP_PRODUCTION_TYPE}" >> $GITHUB_OUTPUT
    echo "opp_name=${OPP_OPERATOR_NAME}" >> $GITHUB_OUTPUT
    echo "opp_version=${OPP_OPERATOR_VERSION}" >> $GITHUB_OUTPUT
    echo "opp_changed_ci_yaml=${OPP_CI_YAML_CHANGED}" >> $GITHUB_OUTPUT
    echo "opp_ver_overwrite=${OPP_VER_OVERWRITE}" >> $GITHUB_OUTPUT
    echo "opp_update_graph=${OPP_UPDATEGRAPH}" >> $GITHUB_OUTPUT

    echo "Files removed only."
    if [ ! -d ${OPP_OPERATORS_DIR}/${OPP_OPERATOR_NAME} ];then
      OPP_OP_DELETE=1
      DELETE_APPREG=1
      echo "opp_release_delete_appreg=${DELETE_APPREG}"
      echo "opp_release_delete_appreg=${DELETE_APPREG}" >> $GITHUB_OUTPUT
      echo "opp_test_ready=${OPP_TEST_READY}"
      echo "opp_release_ready=${OPP_RELEASE_READY}"
      echo "opp_op_delete=$OPP_OP_DELETE"
      echo "opp_ver_overwrite=$OPP_VER_OVERWRITE"
      echo "opp_op_delete=${OPP_OP_DELETE}" >> $GITHUB_OUTPUT
      echo "opp_is_modified=$OPP_IS_MODIFIED" >> $GITHUB_OUTPUT
      echo "Directory '${OPP_OPERATORS_DIR}/${OPP_OPERATOR_NAME}' is removed. This is OK."

      exit 0
    else
      echo "Directory '${OPP_OPERATORS_DIR}/${OPP_OPERATOR_NAME}' is NOT removed. Searching for remaining versions"
      for f in $(find ${OPP_OPERATORS_DIR}/${OPP_OPERATOR_NAME} -type f);do
        [[ $f == *ci.yaml ]] && continue
        OPP_ADDED_MODIFIED_FILES="$OPP_ADDED_MODIFIED_FILES $f"

      done
      echo "Final modified files are :"
      echo "$OPP_ADDED_MODIFIED_FILES"
      [ -n "$OPP_ADDED_MODIFIED_FILES" ] && OPP_TEST_READY=1
    fi

  else
    REMOVED_VERSIONS=$(echo -e "${FILES// /\\n}" | uniq | sort -r)
    FILES=
  fi
fi

# Only MODIFIED_FILES here
OPP_ADDED_MODIFIED_FILES="$OPP_ADDED_MODIFIED_FILES $OPP_RENAMED_FILES"

FILES=
for sf in ${OPP_ADDED_MODIFIED_FILES}; do
  echo "$sf"
  # Check if .github/ dir is modified
  [[ $sf == .github* ]] && OPP_CHANGES_GITHUB=1 && continue
  [[ $sf == scripts* ]] && OPP_CHANGES_CI=1 && continue
  [[ $sf == ci* ]] && OPP_CHANGES_CI=1 && continue
  [[ $sf == docs* ]] && OPP_CHANGES_DOCS=1 && continue
  [[ $sf == operators* ]] ||  { echo "Not alloved changes outside operators directory. Affected file : '$sf' !!! Exiting ..."; exit 1; }
  [[ $sf == *Dockerfile* ]] && OPP_CHANGES_DOCKERFILE=1 && continue
  [[ $sf == operators* ]] && OPP_CHANGES_IN_OPERATORS_DIR=1
  # [[ $sf == upstream-community-operators* ]] && OPP_CHANGES_STREAM_UPSTREAM=1

  [[ $sf == *package.yaml ]] && OPP_CHANGES_PACKAGE_FILE=1 && continue
  [[ $sf == *ci.yaml ]] && OPP_CI_YAML_CHANGED=1 && continue
  [[ $sf == *mkdocs.yml ]] && continue

  # [[ $OPP_CHANGES_IN_OPERATORS_DIR -eq 0 ]] && [[ $OPP_CHANGES_STREAM_UPSTREAM -eq 0 ]] && { echo "No changes 'community-operators' or 'upstream-community-operators' Skipping test ..."; OPP_TEST_READY=0; }

  OPERATOR_PATH=$(echo $sf | cut -d '/' -f 1-3)
  [ -f $OPERATOR_PATH ] && { echo "Operator path '$OPERATOR_PATH' is file and it should be directory !!!"; exit 1; }
  FILES="$FILES $OPERATOR_PATH"

  # Check if outdside of "community-operators" and "upstream-community-operators"
done

echo ""

for sf in ${OPP_MODIFIED_FILES}; do
  echo "modified only: $sf"

  [[ $sf == *package.yaml ]] && continue
  [[ $sf == *ci.yaml ]] && OPP_CI_YAML_MODIFIED=1 && continue
  [[ $sf == *Dockerfile* ]] && OPP_CHANGES_DOCKERFILE=1 && continue
  if [[ $sf == *.clusterserviceversion.yaml ]];then
    OPP_MODIFIED_CSVS="$sf $OPP_MODIFIED_CSVS"
  else
    OPP_MODIFIED_OTHERS="$sf $OPP_MODIFIED_OTHERS"
  fi
  OPP_IS_MODIFIED=1
done
echo "OPP_MODIFIED_CSVS=$OPP_MODIFIED_CSVS"
echo "OPP_MODIFIED_OTHERS=$OPP_MODIFIED_OTHERS"

# [[ $OPP_CHANGES_IN_OPERATORS_DIR -eq 0 ]] && [[ $OPP_CHANGES_STREAM_UPSTREAM -eq 0 ]] && [[ $OPP_CI_YAML_CHANGED -eq 0 ]] && { echo "No changes 'community-operators' or 'upstream-community-operators' !!! Skipping test ..."; OPP_TEST_READY=0; }

# [[ $OPP_CHANGES_IN_OPERATORS_DIR -eq 1 ]] && [[ $OPP_CHANGES_STREAM_UPSTREAM -eq 1 ]] && { echo "Changes in both 'community-operators' and 'upstream-community-operators' dirs !!! Exiting ..."; echo "opp_error_code=2" >> $GITHUB_OUTPUT; exit 1; }

[[ $OPP_CHANGES_GITHUB -eq 1 ]] && [[ $OPP_ALLOW_CI_CHANGES -eq 0 ]] && { echo "Changes in '.github' dir, but 'allow/ci-changes' label is not set !!!"; echo "opp_error_code=3" >> $GITHUB_OUTPUT; OPP_TEST_READY=0; exit 1; }
[[ $OPP_CHANGES_CI -eq 1 ]] && [[ $OPP_ALLOW_CI_CHANGES -eq 0 ]] && { echo "Changes in ci, but 'allow/ci-changes' label is not set !!!"; echo "opp_error_code=3" >> $GITHUB_OUTPUT; OPP_TEST_READY=0; exit 1; }
[[ $OPP_CHANGES_DOCS -eq 1 ]] && [[ $OPP_ALLOW_CI_CHANGES -eq 0 ]] && { echo "Changes in docs, but 'allow/ci-changes' label is not set !!!"; echo "opp_error_code=3" >> $GITHUB_OUTPUT; OPP_TEST_READY=0; exit 1; }
# [[ $OPP_CHANGES_IN_OPERATORS_DIR -eq 1 || $OPP_CHANGES_IN_OPERATORS_DIR -eq 1 ]] && [[ $OPP_TEST_READY -eq 0 ]] && { echo "Error: Operator changes detected with ci changes and 'allow/ci-changes' is not set !!! Exiting ..."; echo "opp_error_code=3" >> $GITHUB_OUTPUT;  exit 1; }
# [[ $OPP_CHANGES_IN_OPERATORS_DIR -eq 0 && $OPP_CHANGES_IN_OPERATORS_DIR -eq 0 ]] && [[ $OPP_TEST_READY -eq 0 ]] && { echo "Nothing to test"; exit 0; }
[[ $OPP_TEST_READY -eq 0 ]] && { echo "Nothing to test"; exit 0; }

# [[ $OPP_CHANGES_IN_OPERATORS_DIR -eq 1 ]] && OPP_OPERATORS_DIR="community-operators"
# [[ $OPP_CHANGES_STREAM_UPSTREAM -eq 1 ]] && OPP_OPERATORS_DIR="upstream-community-operators"

if [[ $OPP_CHANGES_IN_OPERATORS_DIR -eq 1 ]] && [[ $OPP_CI_YAML_CHANGED -eq 1 ]] && [ ! -n "$FILES" ];then
  OPP_CI_YAML_ONLY=1
  OPP_OPERATOR_NAME=$(echo ${OPP_ADDED_MODIFIED_FILES} | cut -d '/' -f 2)
  if [[ $OPP_CI_YAML_ONLY -eq 1 ]];then
    if [[ $OPP_PROD -ge 1 ]];then
      OPP_OPERATOR_VERSION="sync"
    else
      OPP_OPERATOR_VERSION="$(find $OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME -type f -name "*.clusterserviceversion.yaml" | sort --version-sort | tail -n 1 | cut -d '/' -f 3)"
    fi
    OPP_OPERATOR_VERSIONS_ALL="$(find $OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME -type f -name "*.clusterserviceversion.yaml" | sort --version-sort | cut -d '/' -f 3 | tr '\n' ' ')"
    OPP_OPERATOR_VERSIONS_ALL_LATEST="$(find $OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME -type f -name "*.clusterserviceversion.yaml" | sort --version-sort | tail -n 1 | cut -d '/' -f 3)"
  fi

  echo "opp_ci_yaml_only=${OPP_CI_YAML_ONLY}" >> $GITHUB_OUTPUT
  echo "opp_ci_yaml_changed=${OPP_CI_YAML_CHANGED}" >> $GITHUB_OUTPUT
  echo "Only ci.yaml was changed : ${OPP_ADDED_MODIFIED_FILES}"

elif [[ $OPP_CHANGES_IN_OPERATORS_DIR -eq 1 ]] && [[ $OPP_CHANGES_PACKAGE_FILE -eq 1 ]] && [ ! -n "$FILES" ];then
  OPP_CHANGES_PACKAGE_FILE_ONLY=1
  OPP_RELEASE_READY=1
  OPP_OP_DELETE=1
  OPP_OPERATOR_NAME=$(echo ${OPP_ADDED_MODIFIED_FILES} | cut -d '/' -f 2)
  if [[ $OPP_CHANGES_PACKAGE_FILE_ONLY -eq 1 ]];then
    if [[ $OPP_PROD -ge 1 ]];then
      OPP_OPERATOR_VERSION="sync"
    else
      OPP_OPERATOR_VERSION="$(find $OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME -type f -name "*.clusterserviceversion.yaml" | sort --version-sort | tail -n 1 | cut -d '/' -f 3)"
    fi
    OPP_OPERATOR_VERSIONS_ALL="$(find $OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME -type f -name "*.clusterserviceversion.yaml" | sort --version-sort | cut -d '/' -f 3 | tr '\n' ' ')"
    OPP_OPERATOR_VERSIONS_ALL_LATEST="$(find $OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME -type f -name "*.clusterserviceversion.yaml" | sort --version-sort | tail -n 1 | cut -d '/' -f 3)"
  fi

  # Act same way as it would be ci.yaml only file change
  echo "opp_ci_yaml_only=${OPP_CHANGES_PACKAGE_FILE_ONLY}" >> $GITHUB_OUTPUT
  echo "opp_ci_yaml_changed=${OPP_CHANGES_PACKAGE_FILE}" >> $GITHUB_OUTPUT
  echo "Only package file was changed : ${OPP_ADDED_MODIFIED_FILES}"

else
  echo "FILES: $FILES"

  VERSIONS=$(echo -e "${FILES// /\\n}" | uniq | sort -r)

  LATEST="$(echo -e $VERSIONS | cut -d ' ' -f 1)"
  OPP_OPERATOR_NAME=$(echo $LATEST | cut -d '/' -f 2)
  OPP_OPERATOR_VERSION=$(echo $LATEST | cut -d '/' -f 3)
  OPP_OPERATOR_VERSIONS_ALL="$(find $OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME -type f -name "*.clusterserviceversion.yaml" | sort --version-sort | cut -d '/' -f 3 | tr '\n' ' ')"
  OPP_OPERATOR_VERSIONS_ALL_LATEST="$(find $OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME -type f -name "*.clusterserviceversion.yaml" | sort --version-sort | tail -n 1 | cut -d '/' -f 3)"

  OPP_OPERATOR_VERSIONS=
  for v in $VERSIONS;do
    TMP_OP_NAME=$(echo $v | cut -d '/' -f 2)
    OPP_OPERATOR_VERSIONS="$(echo $v| cut -d '/' -f 3) $OPP_OPERATOR_VERSIONS"
    [ "$OPP_OPERATOR_NAME" = "$TMP_OP_NAME" ] || { echo "Error: Multiple operators are changed !!! Detected:'$OPP_OPERATOR_NAME' and '$TMP_OP_NAME' !!! Exiting ..."; OPP_TEST_READY=0; echo "opp_error_code=5" >> $GITHUB_OUTPUT;  exit 1;  }
  done
  # remove trailing space
  OPP_OPERATOR_VERSIONS=$(echo $OPP_OPERATOR_VERSIONS | sed 's/ *$//g')
  OPP_OPERATOR_VERSIONS=$(echo $OPP_OPERATOR_VERSIONS | tr ' ' '\n' | uniq |  tr '\n' ' ' | sed 's/ *$//')

  OPP_OPERATOR_VERSIONS_REMOVED=
  for v in $REMOVED_VERSIONS;do
    OPP_OPERATOR_VERSIONS_REMOVED="$(echo $v| cut -d '/' -f 3) $OPP_OPERATOR_VERSIONS_REMOVED"
  done
  # remove trailing space
  OPP_OPERATOR_VERSIONS_REMOVED=$(echo $OPP_OPERATOR_VERSIONS_REMOVED | sed 's/ *$//g')

  [[ $OPP_PROD -ge 1 ]] && OPP_RELEASE_READY=1



  OPP_OPERATOR_VERSIONS_COUNT=0
  [ -n "$OPP_OPERATOR_VERSIONS" ] && OPP_OPERATOR_VERSIONS_COUNT=$(echo $OPP_OPERATOR_VERSIONS | tr ' ' '\n' | wc -l)
  OPP_OPERATOR_VERSIONS_REMOVED_COUNT=0
  [ -n "$OPP_OPERATOR_VERSIONS_REMOVED" ] && OPP_OPERATOR_VERSIONS_REMOVED_COUNT=$(echo $OPP_OPERATOR_VERSIONS_REMOVED | tr ' ' '\n' | wc -l)


  OPP_OPERATOR_VERSIONS_ALL_COUNT=0
  [ -n "$OPP_OPERATOR_VERSIONS_ALL" ] && OPP_OPERATOR_VERSIONS_ALL_COUNT=$(echo $OPP_OPERATOR_VERSIONS_ALL | tr ' ' '\n' | wc -l)

  echo "Versions Count: CHANGED[$OPP_OPERATOR_VERSIONS] REMOVED[$OPP_OPERATOR_VERSIONS_REMOVED]"

  # [[ $OPRT -eq 1 ]] && [ -n "$OPP_OPERATOR_VERSIONS_REMOVED" ] && [[ ! $OPP_RECREATE -eq 1 ]] && [ "$OPP_OPERATOR_VERSIONS_REMOVED" != "$OPP_OPERATOR_VERSIONS_ALL_LATEST" ] && { echo "Error: Old versions [$OPP_OPERATOR_VERSIONS_REMOVED] were removed and 'allow/operator-recreate' is NOT set !!! Please set it first !!! Exiting ..."; echo "opp_error_code=6" >> $GITHUB_OUTPUT; exit 1;  }
  # [[ $OPP_OPERATOR_VERSIONS_COUNT -eq 1 ]] && [[ $OPP_IS_MODIFIED -eq 1 ]] && [[ $OPP_OPERATOR_VERSIONS_REMOVED_COUNT -gt 0 ]] && OPP_SET_LABEL_OPERATOR_RECREATE=1 && OPP_RECREATE=1 && OPP_SET_LABEL_OPERATOR_VERSION_OVERWRITE=0 && OPP_VER_OVERWRITE=0

  [[ $OPP_OPERATOR_VERSIONS_COUNT -eq 1 ]] && [[ $OPP_IS_MODIFIED -eq 1 ]] && OPP_SET_LABEL_OPERATOR_VERSION_OVERWRITE=1
  [[ $OPP_OPERATOR_VERSIONS_COUNT -eq 1 ]] && [[ $OPP_IS_MODIFIED -eq 1 ]] && [[ $OPP_OPERATOR_VERSIONS_REMOVED_COUNT -gt 0 ]] && OPP_SET_LABEL_OPERATOR_RECREATE=1 && OPP_RECREATE=1 && OPP_OP_DELETE=1 && OPP_SET_LABEL_OPERATOR_VERSION_OVERWRITE=0 && OPP_VER_OVERWRITE=0
  [[ $OPP_OPERATOR_VERSIONS_COUNT -gt 1 ]] && OPP_SET_LABEL_OPERATOR_RECREATE=1 && OPP_RECREATE=1 && OPP_SET_LABEL_OPERATOR_VERSION_OVERWRITE=0 && OPP_VER_OVERWRITE=0
  [[ $OPP_OPERATOR_VERSIONS_REMOVED_COUNT -gt 0 ]] && OPP_SET_LABEL_OPERATOR_RECREATE=1 && OPP_RECREATE=1 && OPP_OP_DELETE=1 && OPP_SET_LABEL_OPERATOR_VERSION_OVERWRITE=0 && OPP_VER_OVERWRITE=0
  [[ $OPP_OPERATOR_VERSIONS_ALL_COUNT -eq 1 ]] && OPP_IS_NEW_OPERATOR=1 && OPP_RECREATE=1 && OPP_SET_LABEL_OPERATOR_RECREATE=1 && OPP_VER_OVERWRITE=0 && OPP_SET_LABEL_OPERATOR_VERSION_OVERWRITE=0

  # [[ $OPRT -eq 0 ]] && [[ $OPP_OPERATOR_VERSIONS_COUNT -gt 1 ]] && [[ ! $OPP_RECREATE -eq 1 ]] && { echo "Error: Multiple versions [$OPP_OPERATOR_VERSIONS] were modified and 'allow/operator-recreate' is NOT set !!! Please set it first !!! Exiting ..."; echo "opp_error_code=5" >> $GITHUB_OUTPUT; exit 1;  }


  [[ $OPP_VER_OVERWRITE -eq 1 ]] && [[ $OPP_RECREATE -eq 1 ]] && { echo "Labels 'allow/operator-version-overwrite' and 'allow/operator-recreate' is set. Only one label can be set !!! Exiting ..."; echo "opp_error_code=1" >> $GITHUB_OUTPUT; exit 1; }

  # [[ $OPRT -eq 1 ]] && [[ $OPP_CI_YAML_MODIFIED -eq 1 ]] && [[ $OPP_CI_YAML_ONLY -eq 0 ]] && { echo "We support only a single file modification in case of 'ci.yaml' file. If you want to update it, please make an extra PR with 'ci.yaml' file modification only !!! More info : $OPP_CURRENT_PROJECT_DOC/operator-ci-yaml/."; echo "opp_error_code=7" >> $GITHUB_OUTPUT; exit 1; }

fi

echo "opp_production_type=${OPP_PRODUCTION_TYPE}" >> $GITHUB_OUTPUT
echo "opp_name=${OPP_OPERATOR_NAME}" >> $GITHUB_OUTPUT

yq --version || { echo "Command 'yq' could not be found !!!"; exit 1; }

if [[ OPP_REVIEWERS_ENABLED -eq 1 ]];then
  CI_YAML_REMOTE="https://raw.githubusercontent.com/$OPP_THIS_REPO/$OPP_THIS_BRANCH/$OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME/ci.yaml"
  CI_YAML_REMOTE_LOCAL="/tmp/ci.yaml"
  echo "Downloading '$CI_YAML_REMOTE' to $CI_YAML_REMOTE_LOCAL ... "
  rm -f $CI_YAML_REMOTE_LOCAL || true
  curl -s -f -o $CI_YAML_REMOTE_LOCAL $CI_YAML_REMOTE || true
  # Hanlde remote ci.yaml for authorized changes
  if [ -f $CI_YAML_REMOTE_LOCAL ];then
    echo "File '$CI_YAML_REMOTE' was found ..."
    if [ -n "$OPP_PR_AUTHOR" ];then
      TEST_REVIEWERS=$(cat  $CI_YAML_REMOTE_LOCAL | yq '.reviewers')
      for row in $(echo "${TEST_REVIEWERS}" | yq -r '.[]'); do
        echo "checking if reviewer '$row' is pr author '$OPP_PR_AUTHOR' ..."
        if [ "${OPP_PR_AUTHOR,,}" == "${row,,}" ];then
          echo "[AUTHORIZED_CHANGES=1] : Author '${OPP_PR_AUTHOR,,}' is in reviewer list" && OPP_AUTHORIZED_CHANGES=1
        else
          OPP_REVIEVERS="@$row,$OPP_REVIEVERS"
        fi
      done
      OPP_REVIEVERS=$(echo $OPP_REVIEVERS | sed 's/\(.*\),/\1 /')
      [[ $OPP_AUTHORIZED_CHANGES -eq 1 ]] && OPP_REVIEVERS=""
    fi
    if [ -n "$OPP_APPROVED_LIST" ];then
      TEST_REVIEWERS=$(cat  $CI_YAML_REMOTE_LOCAL | yq '.reviewers')
      echo "TEST_REVIEWERS=$TEST_REVIEWERS"
      echo "OPP_APPROVED_LIST=$OPP_APPROVED_LIST"
      for row in $(echo "${TEST_REVIEWERS}" | yq -r '.[]'); do
        for approver in $OPP_APPROVED_LIST;do
          echo "checking if reviewer '$row' is approver '$approver' ..."
          if [ "${approver,,}" == "${row,,}" ];then
            echo "[AUTHORIZED_CHANGES=1] : Approver '${approver,,}' is in reviewer list" && OPP_AUTHORIZED_CHANGES=1
          fi
        done
      done

    fi
    echo "OPP_AUTHORIZED_CHANGES=$OPP_AUTHORIZED_CHANGES"
  else
    echo "File '$CI_YAML_REMOTE' was not found ..."
  fi

  if [[ $OPP_TEST_READY -eq 1 ]];then
    if [ -f $OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME/ci.yaml ];then
      TEST_REVIEWERS=$(cat $OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME/ci.yaml | yq '.reviewers')
      # [ "$TEST_REVIEWERS" == "null" ] &&  { echo "We require that file '$OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME/ci.yaml' contains 'reviewers' array field with one reviewer set as minimum !!! More info : $OPP_CURRENT_PROJECT_DOC/operator-ci-yaml/ !!!"; echo "opp_error_code=4" >> $GITHUB_OUTPUT; exit 1; }

      if [ "$TEST_REVIEWERS" != "null" ];then
        TEST_REVIEWERS=$(cat $OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME/ci.yaml | yq '.reviewers | length' || echo 0)
        [[ $TEST_REVIEWERS -eq 0 ]] && { echo "We require that file '$OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME/ci.yaml' contains 'reviewers' array field and it has at least one reviewer set!!! More info : $OPP_CURRENT_PROJECT_DOC/operator-ci-yaml/ !!!"; echo "opp_error_code=4" >> $GITHUB_OUTPUT; exit 1; }
      else
        echo "File '$OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME/ci.yaml' doesn't contain 'reviewers' array field !!! If one wants to add reviewers (truested-authors) More info : $OPP_CURRENT_PROJECT_DOC/operator-ci-yaml/. !!!"
        OPP_ERROR_CODE=10
      fi
      TEST_UPDATE_GRAPH=$(cat $OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME/ci.yaml | yq '.updateGraph')
      [ $TEST_UPDATE_GRAPH == "null" ] && OPP_UPDATEGRAPH=0
      echo "OPP_UPDATEGRAPH=$OPP_UPDATEGRAPH"

    else
      echo "File '$OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME/ci.yaml' is present !!! If one wants to add reviewers (truested-authors) More info : $OPP_CURRENT_PROJECT_DOC/operator-ci-yaml/. !!!"
      OPP_ERROR_CODE=10
    fi
  fi
fi

if [ -f $OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME/ci.yaml ];then
  echo "File '$OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME/ci.yaml' exitst"
  PACKAGEMANIFEST_CLUSTER_VERSION_LABEL=$(cat $OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME/ci.yaml | yq -r '.packagemanifestClusterVersionLabel')
  echo "packagemanifestClusterVersionLabel : $PACKAGEMANIFEST_CLUSTER_VERSION_LABEL"
  [ "$PACKAGEMANIFEST_CLUSTER_VERSION_LABEL" == "auto" ] && OPP_AUTO_PACKAGEMANIFEST_CLUSTER_VERSION_LABEL=1
fi


if [[ OPP_INSTALLATION_SKIPED -eq 1 ]];then
  echo "[BEFORE] OPP_INSTALLATION_SKIP_FOUND=$OPP_INSTALLATION_SKIP_FOUND"
  CI_CONF_REMOTE="https://raw.githubusercontent.com/$OPP_THIS_REPO/$OPP_THIS_BRANCH/ci/pipeline-config-$OPP_PRODUCTION_TYPE.yaml"
  CI_CONF_REMOTE_LOCAL="/tmp/pipeline-config.yaml"
  echo "Downloading '$CI_CONF_REMOTE' to $CI_CONF_REMOTE_LOCAL ... "
  rm -f $CI_CONF_REMOTE_LOCAL || true
  curl -s -f -o $CI_CONF_REMOTE_LOCAL $CI_CONF_REMOTE || true

  if [ -f $CI_CONF_REMOTE_LOCAL ];then
    echo "Searching 'production.test.installation_skip' in '$CI_CONF_REMOTE_LOCAL' ..."
    TEST_INSTALLATION_SKIP=$(cat  $CI_CONF_REMOTE_LOCAL | yq '.production.test.installation_skip')
    if [[ $TEST_INSTALLATION_SKIP != null ]];then
      for row in $(echo "${TEST_INSTALLATION_SKIP}" | yq -r '.[]'); do
        echo "TEST_INSTALLATION_SKIP -> row=$row $OPP_OPERATOR_NAME"
        if [[ $OPP_OPERATOR_NAME == $row* ]];then
          OPP_INSTALLATION_SKIP_FOUND=1
          break
        fi
      done
    else
      echo "Warning : .production.test.installation_skip is not found in '$CI_CONF_REMOTE'"
    fi
  fi
fi
echo "OPP_INSTALLATION_SKIP_FOUND=$OPP_INSTALLATION_SKIP_FOUND"
# exit 1

if [[ $OPP_INSTALLATION_SKIP_FOUND -eq 1 ]] && [[ $OPP_PROD -eq 1 ]];then
  echo "opp_release_ready=0" >> $GITHUB_OUTPUT
  echo "Installation was skipped. No release ..."
  exit 0
fi

[[ $OPP_VER_OVERWRITE -eq 0 ]] && [[ $OPP_SET_LABEL_OPERATOR_VERSION_OVERWRITE -eq 1 ]] && OPP_VER_OVERWRITE=$OPP_SET_LABEL_OPERATOR_VERSION_OVERWRITE

# OPP_PR_TITLE="$OPP_OPERATORS_DIR"
OPP_PR_TITLE="operator"
[[ $OPRT -eq 1 ]] && [[ $OPP_VER_OVERWRITE -eq 1 ]] && OPP_PR_TITLE="$OPP_PR_TITLE [O]"
[[ $OPRT -eq 1 ]] && [[ $OPP_RECREATE -eq 1 ]] && [[ $OPP_IS_NEW_OPERATOR -eq 0 ]] && OPP_PR_TITLE="$OPP_PR_TITLE [R]"
[[ $OPRT -eq 1 ]] && [[ $OPP_RECREATE -eq 1 ]] && [[ $OPP_IS_NEW_OPERATOR -eq 1 ]] && OPP_PR_TITLE="$OPP_PR_TITLE [N]"
[[ $OPRT -eq 1 ]] && [[ $OPP_CI_YAML_CHANGED -eq 1 ]] && OPP_PR_TITLE="$OPP_PR_TITLE [CI]"
[[ $OPRT -eq 1 ]] && [[ $OPP_CHANGES_PACKAGE_FILE_ONLY -eq 1 ]] && OPP_PR_TITLE="$OPP_PR_TITLE [PK]"
OPP_PR_TITLE="$OPP_PR_TITLE $OPP_OPERATOR_NAME"
[[ $OPP_CI_YAML_ONLY -eq 0 ]] && OPP_PR_TITLE="$OPP_PR_TITLE ($OPP_OPERATOR_VERSIONS)"

function detect_k8s_max() {
    echo "Detecting if k8s max version is defined..."
    OPERATOR_VERSION_PATH_LATEST_CSV_PATH=$(find $LATEST -name "*clusterserviceversion*")
    echo "OPERATOR_VERSION_PATH_LATEST_CSV_PATH=$OPERATOR_VERSION_PATH_LATEST_CSV_PATH"
    ls $OPERATOR_VERSION_PATH_LATEST_CSV_PATH
    curl -L https://github.com/mikefarah/yq/releases/download/2.2.1/yq_linux_amd64 -o /tmp/yq
    chmod +x /tmp/yq
    yq --version
    KIND_KUBE_VERSION_DETECTED_RAW=$(/tmp/yq r "$OPERATOR_VERSION_PATH_LATEST_CSV_PATH" "metadata.annotations.[operatorhub.io/ui-metadata-max-k8s-version]")
    KIND_KUBE_VERSION_DETECTED_CORE=$(echo $KIND_KUBE_VERSION_DETECTED_RAW| cut -f -2 -d'.')

    echo "KIND_KUBE_VERSION_DETECTED_RAW=$KIND_KUBE_VERSION_DETECTED_RAW"
    echo "KIND_KUBE_VERSION_DETECTED_CORE=$KIND_KUBE_VERSION_DETECTED_CORE"


    if [ "$KIND_KUBE_VERSION_DETECTED_CORE" != "null" ]; then

            echo "Detected UI k8s version is not null"

            function semver_compare() {
            SEMVER_BIGGER_OUT_OF_RANGE=0
            SEMVER_SMALLER_OUT_OF_RANGE=0
              local IFS=.
              local i VER1=($1) VER2=($2)
              for ((i=0; i<${#VER1[@]}; i++))
                  do
                      if ((10#${VER1[i]} > 10#${VER2[i]}))
                      then
                          SEMVER_BIGGER_OUT_OF_RANGE=1
                      fi
                      if ((10#${VER1[i]} < 10#${VER2[i]}))
                      then
                          SEMVER_SMALLER_OUT_OF_RANGE=1
                      fi
                  done
            }

            semver_compare $KIND_KUBE_VERSION_DETECTED_CORE $KIND_MIN_SUPPORTED

            if [ $SEMVER_SMALLER_OUT_OF_RANGE -eq 1 ]; then
              echo "Kubernetes $KIND_KUBE_VERSION_DETECTED_CORE defined in 'operatorhub.io/ui-metadata-max-k8s-version' is not supported.       [FAIL]"
              exit 1
            else

              semver_compare $KIND_KUBE_VERSION_DETECTED_CORE $KIND_MAX_SUPPORTED

              if [ $SEMVER_BIGGER_OUT_OF_RANGE -eq 1 ]; then
                KIND_KUBE_VERSION_DETECTED="v$KIND_MAX_SUPPORTED.${KIND_SUPPORT_TABLE[$KIND_MAX_SUPPORTED]}"
                echo "Bigger, setting KIND_KUBE_VERSION_DETECTED to $KIND_KUBE_VERSION_DETECTED"
              else
                KIND_KUBE_VERSION_DETECTED="v$KIND_KUBE_VERSION_DETECTED_CORE.${KIND_SUPPORT_TABLE[$KIND_KUBE_VERSION_DETECTED_CORE]}"
                echo "In range, setting KIND_KUBE_VERSION_DETECTED to $KIND_KUBE_VERSION_DETECTED"
              fi
            fi

            echo "kind_kube_version=$KIND_KUBE_VERSION_DETECTED" >> $GITHUB_OUTPUT
            echo "Exported $KIND_KUBE_VERSION_DETECTED"
    else
            echo "kind_kube_version=$KIND_KUBE_VERSION_LATEST" >> $GITHUB_OUTPUT # consider KIND_MAX_SUPPORTED instead of latest
            KIND_KUBE_VERSION_DETECTED="$KIND_KUBE_VERSION_LATEST"
            echo "K8S UI version not defined, using from config $KIND_KUBE_VERSION_DETECTED"
    fi

    echo "Kind kube version $KIND_KUBE_VERSION_DETECTED will be installed in an appropriate step."

}

# Handle case when after removal of operator only ci.yaml will be present
if [ -n "$OPP_REMOVED_FILES" ];then
  FILES_IN_OPERATOR_DIR=$(find operators/$OPP_OPERATOR_NAME/ -type f)
  NUM_FILES_IN_OPERATOR_DIR=$(echo $FILES_IN_OPERATOR_DIR | tr ' ' '\n' | wc -l)
  if [[ $NUM_FILES_IN_OPERATOR_DIR -eq 1 ]];then
    CI_YAML_TEST=$(basename $FILES_IN_OPERATOR_DIR)
    [[ $CI_YAML_TEST == "ci.yaml" ]] && OPP_RELEASE_READY=1
  fi
fi


[[ $OPP_PRODUCTION_TYPE == k8s ]] && [[ $OPP_CI_YAML_ONLY == 0 ]] && detect_k8s_max

[[ $OPP_ALLOW_FORCE_RELEASE -eq 1 ]] && OPP_RELEASE_READY=$OPP_ALLOW_FORCE_RELEASE

echo "Latest : $LATEST"
echo "OPP_OPERATOR_VERSION: $OPP_OPERATOR_VERSION"
echo "OPP_OPERATOR_VERSIONS : $OPP_OPERATOR_VERSIONS"
echo "OPP_OPERATOR_VERSIONS_ALL : $OPP_OPERATOR_VERSIONS_ALL"
echo "OPP_OPERATOR_VERSIONS_ALL_LATEST : $OPP_OPERATOR_VERSIONS_ALL_LATEST"
echo "OPP_OPERATOR_VERSIONS_REMOVED : $OPP_OPERATOR_VERSIONS_REMOVED"
echo "OPP_CHANGES_GITHUB=$OPP_CHANGES_GITHUB"
echo "OPP_CHANGES_CI=$OPP_CHANGES_CI"
echo "OPP_CHANGES_DOC=$OPP_CHANGES_DOCS"
echo "OPP_CHANGES_IN_OPERATORS_DIR=$OPP_CHANGES_IN_OPERATORS_DIR"
echo "OPP_CHANGES_STREAM_UPSTREAM=$OPP_CHANGES_STREAM_UPSTREAM"
echo "OPP_CHANGES_DOCKERFILE=$OPP_CHANGES_DOCKERFILE"

echo "OPP_AUTO_PACKAGEMANIFEST_CLUSTER_VERSION_LABEL=$OPP_AUTO_PACKAGEMANIFEST_CLUSTER_VERSION_LABEL"

echo "opp_test_ready=${OPP_TEST_READY}"
echo "opp_release_ready=${OPP_RELEASE_READY}"
echo "opp_production_type=${OPP_PRODUCTION_TYPE}"
echo "opp_name=${OPP_OPERATOR_NAME}"
echo "opp_version=${OPP_OPERATOR_VERSION}"
echo "opp_versions=${OPP_OPERATOR_VERSIONS}"
echo "opp_is_new_operatror=${OPP_IS_NEW_OPERATOR}"
echo "opp_pr_title=${OPP_PR_TITLE}"
echo "opp_pr_revievers=${OPP_REVIEVERS}"

echo "opp_ci_yaml_only=$OPP_CI_YAML_ONLY"
echo "opp_ci_yaml_changed=${OPP_CI_YAML_CHANGED}"
echo "opp_op_delete=$OPP_OP_DELETE"
echo "opp_ver_overwrite=$OPP_VER_OVERWRITE"
echo "opp_recreate=${OPP_RECREATE}"
echo "opp_installation_skipped=$OPP_INSTALLATION_SKIP_FOUND"
echo "opp_set_label_operator_version_overwrite=$OPP_SET_LABEL_OPERATOR_VERSION_OVERWRITE"
echo "opp_set_label_operator_recreate=$OPP_SET_LABEL_OPERATOR_RECREATE"
echo "opp_dockerfile_changed=$OPP_CHANGES_DOCKERFILE"

echo "opp_error_code=$OPP_ERROR_CODE"
echo "opp_authorized_changes=$OPP_AUTHORIZED_CHANGES"


echo "opp_test_ready=${OPP_TEST_READY}" >> $GITHUB_OUTPUT
echo "opp_release_ready=${OPP_RELEASE_READY}" >> $GITHUB_OUTPUT
echo "opp_production_type=${OPP_PRODUCTION_TYPE}" >> $GITHUB_OUTPUT
echo "opp_name=${OPP_OPERATOR_NAME}" >> $GITHUB_OUTPUT
echo "opp_version=${OPP_OPERATOR_VERSION}" >> $GITHUB_OUTPUT
echo "opp_versions=${OPP_OPERATOR_VERSIONS}" >> $GITHUB_OUTPUT
echo "opp_is_new_operatror=${OPP_IS_NEW_OPERATOR}" >> $GITHUB_OUTPUT
echo "opp_pr_title=${OPP_PR_TITLE}" >> $GITHUB_OUTPUT
echo "opp_pr_revievers=${OPP_REVIEVERS}" >> $GITHUB_OUTPUT
echo "opp_ci_yaml_only=${OPP_CI_YAML_ONLY}" >> $GITHUB_OUTPUT
echo "opp_ci_yaml_changed=${OPP_CI_YAML_CHANGED}" >> $GITHUB_OUTPUT
echo "opp_op_delete=${OPP_OP_DELETE}" >> $GITHUB_OUTPUT
echo "opp_ver_overwrite=${OPP_VER_OVERWRITE}" >> $GITHUB_OUTPUT
echo "opp_recreate=${OPP_RECREATE}" >> $GITHUB_OUTPUT
echo "opp_installation_skipped=${OPP_INSTALLATION_SKIP_FOUND}" >> $GITHUB_OUTPUT
echo "opp_update_graph=${OPP_UPDATEGRAPH}" >> $GITHUB_OUTPUT
echo "opp_set_label_operator_version_overwrite=$OPP_SET_LABEL_OPERATOR_VERSION_OVERWRITE" >> $GITHUB_OUTPUT
echo "opp_set_label_operator_recreate=$OPP_SET_LABEL_OPERATOR_RECREATE" >> $GITHUB_OUTPUT
echo "opp_is_modified=$OPP_IS_MODIFIED" >> $GITHUB_OUTPUT
echo "opp_modified_csvs=$OPP_MODIFIED_CSVS" >> $GITHUB_OUTPUT
echo "opp_modified_others=$OPP_MODIFIED_OTHERS" >> $GITHUB_OUTPUT
echo "opp_error_code=$OPP_ERROR_CODE" >> $GITHUB_OUTPUT
echo "opp_authorized_changes=${OPP_AUTHORIZED_CHANGES}" >> $GITHUB_OUTPUT
echo "opp_dockerfile_changed=$OPP_CHANGES_DOCKERFILE" >> $GITHUB_OUTPUT
echo "opp_auto_packagemanifest_cluster_version_label=$OPP_AUTO_PACKAGEMANIFEST_CLUSTER_VERSION_LABEL" >> $GITHUB_OUTPUT


echo "All done"
exit 0
