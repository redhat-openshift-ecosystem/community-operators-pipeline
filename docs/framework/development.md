# Project development structure

## TODO


## Create empty project
The project administrator has to

- create an empty GitHub project
- configure one configuration file
- set up various secrets
- create the directory structure shown bellow

## Generate Github Action workflows

!!! note
    On newly created projects one should copy the file ([upgrade.yaml](https://github.com/redhat-openshift-ecosystem/community-operators-pipeline/blob/main/.github/workflows/upgrade.yaml)) to `.github/workflows/upgrade.yaml` and push it in to `main` branch so `CI Upgrade` workflow is enabled in `Actions` tab in GitHub project.

After the directory and configurations are in place one can generate all workflows by running [Upgrade Action](https://github.com/redhat-openshift-ecosystem/community-operators-pipeline/actions/workflows/upgrade.yaml) from the configured project.

### GitHub Action - CI Upgrade



![PR](../images/ci_upgrade_wk.png)

| Name | Description |
|------|--------|
|`Commit message prefix`|Prefix added to commit message after upgrade|
|`Source repository`|Framework project ([https://github.com/redhat-openshift-ecosystem/community-operators-pipeline](https://github.com/redhat-openshift-ecosystem/community-operators-pipeline))|
|`Source branch`|Framework branch (`upstream-community`)|
|`Playbook branch`|Branch (`upstream-community`) in [ansible playbooks](https://github.com/redhat-openshift-ecosystem/operator-test-playbooks) are taken to upgrade|
|`Cluster type (k8s or ocp)`|Cluster type for repo. Possible options `k8s` or `ocp`|
|`From index (quay.io/operator_testing/index_empty:latest)`|Optional parameter to initialize or copy index image to nonexisten images|


# Branches

## `ci/dev` vs `ci-latest`

## `upstream-community-dev` vs `upstream-community`
### How to trigger playbook image build
### Custom de image from custom branch
There is also an option to use your own branch `upstream-community-dev-<SOMETHING>`. Then you can trigger playbook `dev` image build the same way as described above.

## Playbook image build
