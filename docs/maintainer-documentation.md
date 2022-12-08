# Maintainer Documentation

## Overview
The community team is responsible for reviewing the following:

- [OCP operators](https://github.com/redhat-openshift-ecosystem/community-operators-prod/pulls)
- [K8S operators](https://github.com/k8s-operatorhub/community-operators/pulls)

When a pull request (PR) is opened, tests are automatically triggered to ensure that it meets all quality standards. If the PR passes these tests, it is automatically merged, and the new operator is published to a specific index. 

In order for an automatic merge to be executed, three labels must be present:

- `package-validated`
- `installation-validated`
- `authorized-changes`

## Package-validated
To ensure that a release pipeline will not fail, a simulated local release is triggered. It is executing the same steps as sharp lease, the only difference is that everything is happening locally and not pushing to any official registry.

When a simulated release to an index was successful, the label `package-validated` is applied.

There are three tests as described below.

### Orange test
Simulating a release of an affected operator to the current index(es). Helpful to prevent future failures on current indexes.

### Lemon test
It catches incompatibilities in a release of a new index from scratch. Orange, lemon even kiwi in some cases have to be green which applies `package-validated` label.

### Kiwi test
Basic checks like linting, etc.
In k8s pipeline, it is also testing operator installation and will apply `installation-validated` label. 

## Installation-validated
This means that the pipeline can install the operator.

For K8S it is executed during a kiwi test.

For OCP, prow jobs for every supported OCP are triggered.

### Prow job
For every index we support, a dedicated cluster is started and we are testing if operator installation without any problems. If the operator will not be released to some cluster, an installation test is not needed. In this case, a specific installation test passes early without any installation attempt.

To debug a red prow job go to `Details -> Artifacts -> artifacts/deploy-operator-on-openshift/deploy-operator/build-log.txt`

When all supported OCP clusters are green a label `installation-validated` is applied.

## Authorized-changes

There are a few reasons why the `authorized-changes` label may be missing from a PR:

### New operator

If the `new-operator` label is present, the following steps should be taken:

1. Copy the contents of the clusterserviceversion.yaml file to https://operatorhub.io/preview
2. Visually inspect the content to ensure that it looks correct and that all fields on the right do not contain `N/A`, except for the channel field. The channel field has no ability to display any information.

### No reviewer in `ci.yaml` file

If the `authorized-changes` label is missing and the `ci.yaml` file does not include a reviewer, the following step should be taken:

- Apply the authorized-changes label to the PR.

### An author is not in the reviewer list in `ci.yaml` and `ci.yaml` file was not modified

If the `@contributor_name please approve` message is displayed, indicating that the author of the PR is not in the reviewer list in the `ci.yaml` file and the `ci.yaml` file has not been modified, the following steps should be taken:

1. Wait for approval from a reviewer who is listed in the `ci.yaml` file.
2. If the `authorized-changes` label is not set after the approval, follow one of the three options documented [here](https://redhat-openshift-ecosystem.github.io/community-operators-prod/self-merge-updates/#how-can-i-approve-a-pr-against-my-operator) to set it.

### An author is not in the reviewer list in ci.yaml and ci.yaml file is modified

If the `/hold Please note that ci.yaml was changed` message is displayed, indicating that the author of the PR is not in the reviewer list in the `ci.yaml` file and the `ci.yaml` file has been modified, the following steps should be taken:

1. Wait for approval from a reviewer who is listed in the `ci.yaml` file.
2. If necessary, add the `/unhold` command to the PR to trigger the worklfow.
3. If the `authorized-changes` label is not set after approval, follow one of the three options documented [here](https://redhat-openshift-ecosystem.github.io/community-operators-prod/self-merge-updates/#how-can-i-approve-a-pr-against-my-operator)

## Changes to an existing operator
In an ideal world, a contributor is opening a new PR with a new operator version every time. However, in reality, the contributor needs to update an existing operator in rare cases. A current pipeline allows it because it always removes an existing package from an index and also creates a new bundle with the same tag if needed.

In general, it is not recommended to overwrite an existing operator version. But if there is some typo in the description or something cosmetic. 

The current setup allows cosmetic changes defined in [`local.yml`](https://github.com/redhat-openshift-ecosystem/operator-test-playbooks/blob/upstream-community/upstream/local.yml) as `dc_changes_allowed` variable.

Pipeline detects a cosmetic change and removes the whole package from an index, then adds the package in the current state containing already changed (new) bundles.

In some cases, a contributor may have a strong reason to make more significant changes to an existing operator. When a maintainer decides that this reason is valid an exception can be made. Applying `allow/serious-changes-to-existing` label will not fail on noncosmetic change then.

## DCO failed
The pipeline is checking if every commit is signed. This is an easy fix, just follow the steps under `Details` belonging to DCO test.
