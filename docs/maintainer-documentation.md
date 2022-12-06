# Maintainer Documentation

## Overview
The community team is responsible for reviewing the following:

- [OCP operators](https://github.com/redhat-openshift-ecosystem/community-operators-prod/pulls)
- [K8S operators](https://github.com/k8s-operatorhub/community-operators/pulls)

When a pull request (PR) is opened, tests are automatically triggered to ensure that it meets all quality standards. If the PR passes these tests, it is automatically merged, and the new operator is published to a specific index. 

Basically, there are 3 labels which are needed before automatic merge is executed:

- `package-validated`
- `installation-validated`
- `authorized-changes`

## Package-validated
When simulated release to an index was succesfull, the label packge-validated is applied.

There are 3 tests like described bellow.

### Orange test
Simulating a realese of an affected operator to the current index(es). Helpful to prevent future failures on current indexes.

### Lemon test
It catches incompatibilities in release to a new index from scratch.

### Kiwi test
Basic checks like linting, etc.

## Installation-validated
This means that the pipeline is able to install the operator.

For K8S it is executed during kiwi test.

For OCP prow jobs for every supported OCP is triggered.

### Prow job
To debug red prow job go to `Details -> Artifacts -> artifacts/deploy-operator-on-openshift/deploy-operator/build-log.txt`

When all supported OCP clusters are green a label `installation-validated` is applied

## Authorized-changes

There are a few reasons why the `authorized-changes` label may be missing from a PR:

### New operator

If the `new-operator` label is present, the following steps should be taken:

1. Copy the contents of the clusterserviceversion.yaml file to https://operatorhub.io/preview
2. Visually inspect the content to ensure that it looks correct and that all fields on the right do not contain N/A, except for the channel field.

### No reviewer in `ci.yaml` file

If the `authorized-changes` label is missing and the ci.yaml file does not include a reviewer, the following step should be taken:

- Apply the authorized-changes label to the PR.

### Author is not in reviewer list in `ci.yaml` and `ci.yaml` file was not modified

If the `@contributor_name please approve` message is displayed, indicating that the author of the PR is not in the reviewer list in the `ci.yaml` file and the `ci.yaml` file has not been modified, the following steps should be taken:

1. Wait for approval from a reviewer who is listed in the `ci.yaml` file.
2. If the `authorized-changes` label is not set after approval, follow one of the three options documented [here](https://redhat-openshift-ecosystem.github.io/community-operators-prod/self-merge-updates/#how-can-i-approve-a-pr-against-my-operator) to set it.

### Author is not in reviewer list in ci.yaml and ci.yaml file is modified

If the `/hold Please note that ci.yaml was changed` message is displayed, indicating that the author of the PR is not in the reviewer list in the `ci.yaml` file and the `ci.yaml` file has been modified, the following steps should be taken:

1. Wait for approval from a reviewer who is listed in the `ci.yaml` file.
2. If necessary, add the `/unhold` command to the PR to trigger worklfow.
3. If the `authorized-changes` label is not set after approval, follow one of the three options documented [here](https://redhat-openshift-ecosystem.github.io/community-operators-prod/self-merge-updates/#how-can-i-approve-a-pr-against-my-operator)