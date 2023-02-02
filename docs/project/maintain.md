# Maintainance

## Labels

The operator project is using various labels to handle different situations. Here is the list of them and their meaning

| Name | Description |
|------|--------|
|`allow/operator-version-overwrite`| Operator version will be overritten (only cosmetics changes)|
|`allow/serious-changes-to-existing`|User is overwiting field in csv that are not allowed by default via previous label. Maintainer can allow these changes to be applied also.|
|`allow/operator-recreate`| Operator will be recreated (deleted/created). It happens when mutiple versions are modified of operator|
|`allow/ci-changes`| When there are changes outside of `operators` directory maintainer can set this label to skip failing|
|`allow/longer-deployment`| It sets longer time for operator installation timeout|
|`authorized-changes`| The changes are autorized. User can have this automatically when author is in reviever list in the `ci.yaml` file(needs for automerge)|
|`dco-failed`| DCO failed. Commits were not signedoff|
|`package-validated`| Package is validated (needs for automerge)|
|`installation-validated`| Installation is validated (needs for automerge)|
|`installation-skipped`| Installation is skipped. Some operators requested not to test installation |
|`needs-rebase`|User should rebase to latest `main` branch|
|`new-operator`|Label if operator is new. In other words if there is only one version of operator|

## Upgrade
![PR](../images/project-upgrade-action.png)

### GitHub Action - CI Upgrade
On every workflow template and config change, one has to run an upgrade to apply changes for each project.

![PR](../images/project-upgrade-std.png)


| Name | Description |
|------|--------|
|`Commit message prefix`|Prefix added to commit message after upgrade|
|`Source repository`|Framework (workflow templates) project ([https://github.com/redhat-openshift-ecosystem/community-operators-pipeline](https://github.com/redhat-openshift-ecosystem/community-operators-pipeline))|
|`Source branch`|Framework (workflow templates) branch (`ci/latest`) |
|`Playbook branch`|Branch (`upstream-community`) in [ansible playbooks](https://github.com/redhat-openshift-ecosystem/operator-test-playbooks) are taken to upgrade|
|`Cluster type (k8s or ocp)`|Cluster type for repo. Possible options `k8s` or `ocp`|
|`From index (quay.io/operator_testing/index_empty:latest)`|Optional parameter to initialize or copy index image to nonexisten images|