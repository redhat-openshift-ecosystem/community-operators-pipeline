#!/bin/bash
# Operator Pipeline (OPP) env script (opp-env.sh)
set -e
set +o pipefail
OPP_OPRT_REPO=${OPP_OPRT_REPO-""}
OPP_OPRT_SHA=${OPP_OPRT_SHA-""}
OPP_OPRT_SRC_REPO=${OPP_OPRT_SRC_REPO-"operator-framework/community-operators"}
OPP_OPRT_SRC_BRANCH=${OPP_OPRT_SRC_BRANCH-"master"}
#OPP_SCRIPT_ENV_URL=${OPP_SCRIPT_ENV_URL-"https://raw.githubusercontent.com/operator-framework/community-operators/master/scripts/ci/actions-env"}
OPP_SCRIPT_ENV_URL=${OPP_SCRIPT_ENV_URL-"https://raw.githubusercontent.com/operator-framework/community-operators/support/ci_01/ci/scripts/opp-env.sh"}
export OPRT=1

function handleError() {
  OPERATORS_REPO_DIR=/tmp/operators-repo
  OUTFILE=/tmp/pr_rebase.txt
  echo "Problem with rebasing 'repo=https://github.com/$OPP_OPRT_SRC_REPO branch=$OPP_OPRT_SRC_BRANCH' to 'repo=https://github.com/$OPP_OPRT_REPO $OPERATORS_REPO_DIR branch=$BRANCH_NAME' !!!"
  echo "Generating error file '$OUTFILE' !!!"
  echo "git clone https://github.com/$OPP_OPRT_REPO $OPERATORS_REPO_DIR"> $OUTFILE
  echo "cd $OPERATORS_REPO_DIR">> $OUTFILE
  echo "git remote add upstream https://github.com/$OPP_OPRT_SRC_REPO -f" >> $OUTFILE
  echo "git pull --rebase upstream $OPP_OPRT_SRC_BRANCH" >> $OUTFILE
}

echo "OPP_SCRIPT_ENV_URL=$OPP_SCRIPT_ENV_URL"

[ -n "$OPP_OPRT_REPO" ] || { echo "Error: '\$OPP_OPRT_REPO' is empty !!!"; exit 1; }
[ -n "$OPP_OPRT_SHA" ] || { echo "Error: '\$OPP_OPRT_SHA' is empty !!!"; exit 1; }

git clone https://github.com/$OPP_OPRT_REPO operators #> /dev/null 2>&1
echo "cloned https://github.com/$OPP_OPRT_REPO"
cd operators
BRANCH_NAME=$(git branch -a --contains $OPP_OPRT_SHA | grep remotes/ | grep -v HEAD | cut -d '/' -f 2- | head -n 1)
echo "BRANCH_NAME=$BRANCH_NAME"
git checkout $BRANCH_NAME #> /dev/null 2>&1
git log --oneline | head

git config --global user.email "test@example.com"
git config --global user.name "Test User"

git remote add upstream https://github.com/$OPP_OPRT_SRC_REPO -f #> /dev/null 2>&1
echo "added remote https://github.com/$OPP_OPRT_SRC_REPO"
git rev-parse HEAD
echo "git pull --rebase upstream $OPP_OPRT_SRC_BRANCH"
git pull --rebase upstream $OPP_OPRT_SRC_BRANCH || handleError
echo "Repo rebased over branch OPP_OPRT_SRC_BRANCH - $OPP_OPRT_SRC_BRANCH"

export OPP_ADDED_FILES=$(git diff --diff-filter=A upstream/$OPP_OPRT_SRC_BRANCH --name-only | tr '\r\n' ' ')
export OPP_MODIFIED_FILES=$(git diff --diff-filter=M upstream/$OPP_OPRT_SRC_BRANCH --name-only | tr '\r\n' ' ')
export OPP_REMOVED_FILES=$(git diff --diff-filter=D upstream/$OPP_OPRT_SRC_BRANCH --name-only | tr '\r\n' ' ')
export OPP_RENAMED_FILES=$(git diff --diff-filter=R upstream/$OPP_OPRT_SRC_BRANCH --name-only | tr '\r\n' ' ')
export OPP_ADDED_MODIFIED_FILES=$(git diff --diff-filter=AM upstream/$OPP_OPRT_SRC_BRANCH --name-only | tr '\r\n' ' ')
export OPP_ADDED_MODIFIED_RENAMED_FILES=$(git diff --diff-filter=RAM upstream/$OPP_OPRT_SRC_BRANCH --name-only | tr '\r\n' ' ')
export OPP_CURRENT_PROJECT_REPO="$OPP_OPRT_SRC_REPO"
export OPP_CURRENT_PROJECT_BRANCH="$OPP_OPRT_SRC_BRANCH"
echo "OPP_ADDED_MODIFIED_RENAMED_FILES=$OPP_ADDED_MODIFIED_RENAMED_FILES"

BRANCH_NAME=$(echo $BRANCH_NAME | cut -d '/' -f 2-)
echo "BRANCH_NAME=$BRANCH_NAME"
# echo "::set-output name=op_test_repo_branch::$OPP_OPRT_REPO/${BRANCH_NAME}"


[ -z $OPP_ADDED_FILES ] && [ -z $OPP_MODIFIED_FILES ] && [ -z $OPP_REMOVED_FILES ] && [ -z $OPP_RENAMED_FILES ] && [ -z $OPP_ADDED_MODIFIED_FILES ] && [ -z $OPP_ADDED_MODIFIED_RENAMED_FILES ] && { echo "ERROR: No change detected in PR !!! Contact project maintainers about this error !!!"; exit 1; }


echo "OPP_THIS_PR=$OPP_THIS_PR"
curl -s -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/$OPP_THIS_REPO/pulls/$OPP_THIS_PR/reviews > /tmp/approved_list.json
cat /tmp/approved_list.json
export OPP_APPROVED_LIST=$(cat /tmp/approved_list.json | jq -r '[.[-1] | {user: .user.login, state: .state}] | map(select(.state == "APPROVED")) | .[].user' | tr '\n' ' ')
echo "OPP_APPROVED_LIST=$OPP_APPROVED_LIST"
bash <(curl -sL $OPP_SCRIPT_ENV_URL)
