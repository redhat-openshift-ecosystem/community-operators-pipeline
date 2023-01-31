# Development

## Overview

Three main components are used in each pipeline

- [GitHub action workflows](https://github.com/redhat-openshift-ecosystem/community-operators-pipeline/tree/ci/latest/ci/templates/workflow){:target="\_blank"}
- Driver scripts
  - [opp-env.sh](https://github.com/redhat-openshift-ecosystem/community-operators-pipeline/blob/ci/latest/ci/scripts/opp-env.sh){:target="\_blank"}
  - [opp.sh](https://github.com/redhat-openshift-ecosystem/community-operators-pipeline/blob/ci/latest/ci/scripts/opp.sh){:target="\_blank"}
  - [helper scripts](https://github.com/redhat-openshift-ecosystem/community-operators-pipeline/blob/ci/latest/ci/scripts/){:target="\_blank"}
- [Ansible playbooks](https://github.com/redhat-openshift-ecosystem/operator-test-playbooks/tree/upstream-community/upstream){:target="\_blank"} from `upstream-community` branch `upstream` directory

## Process

1. GitHub action workflows are stored as ansible templates and during the [Upgrade](/project/maintain/#github-action-ci-upgrade){:target="\_blank"} process
2. Workflows are resolved using [config files](/framework/overview/#producion-operator-repositories) and applied to the running project.
3. The testing and release pipelines are triggered by these workflows and followed by running `Ansible playbook` with various parameters.
4. These parameters are controlled by [opp.sh](https://github.com/redhat-openshift-ecosystem/community-operators-pipeline/blob/ci/latest/ci/scripts/opp.sh){:target="\_blank"} script
   and the most relevant part is `function ExecParameters()`.
5. These parameters are passed to Ansible Playbook [local.yaml](https://github.com/redhat-openshift-ecosystem/operator-test-playbooks/blob/upstream-community/upstream/local.yml){:target="\_blank"}
6. The playbook is executed inside the container produced by [quay.io/operator_testing/operator-test-playbooks:latest](https://quay.io/repository/operator_testing/operator-test-playbooks){:target="\_blank"} image.

## Production vs. Development

The [Codebase and development](/framework/overview/#codebase-and-development){:target="\_blank"} table shows various branches used for `production` and `development`. Let's summarize it in the table bellow

| Type                                                                                                                    | GitHub action workflows and scripts | Ansible playbooks        | Ansible playbook image                                                                                                                            |
| ----------------------------------------------------------------------------------------------------------------------- | ----------------------------------- | ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| Production                                                                                                              | `ci/latest`                         | `upstream-community`     | [quay.io/operator_testing/operator-test-playbooks:latest](https://quay.io/repository/operator_testing/operator-test-playbooks){:target="\_blank"} |
| [Development or staging](https://github.com/redhat-openshift-ecosystem/community-operators-pipeline){:target="\_blank"} | `ci/dev`                            | `upstream-community-dev` | [quay.io/operator_testing/operator-test-playbooks:dev](https://quay.io/repository/operator_testing/operator-test-playbooks){:target="\_blank"}    |


### GitHub action workflows and scripts

The `ci/latest` and `ci/dev` branches can be used in both production and development projects by specifying the branch name in [Upgrade](/project/maintain/#github-action-ci-upgrade){:target="\_blank"} workflow

### Ansible playbook images

The `latest` and `dev` tag values are used in the project as stated in the configuration file of the project shown in [Producion operator repositories](/framework/overview/#producion-operator-repositories){:target="\_blank"} in `pipline.image` key.

- The `latest` tag is produced automatically by pushing changes into [https://github.com/redhat-openshift-ecosystem/operator-test-playbooks](https://github.com/redhat-openshift-ecosystem/operator-test-playbooks){:target="\_blank"} in `upstream-community` branch.
- The `dev` tag is produced by manually triggering Github Action [Build playbook image](https://github.com/redhat-openshift-ecosystem/operator-test-playbooks/actions/workflows/playbook_image.yml){:target="\_blank"} and choosing a branch that starts with `upstream-community-*`. More info in the script [here](https://github.com/redhat-openshift-ecosystem/operator-test-playbooks/blob/upstream-community/upstream/playbook_version.sh){:target="\_blank"}. The developer should choose a name starting with `upstream-community-*` for the branch before doing development.

### Ansible playbook example

Ansible playbook parameters are controlled by [opp.sh](https://github.com/redhat-openshift-ecosystem/community-operators-pipeline/blob/ci/latest/ci/scripts/opp.sh){:target="\_blank"} script via `ExecParameters()`. The following example shows how `operator_info` is created by [Operator release](https://github.com/redhat-openshift-ecosystem/community-operators-pipeline/blob/main/.github/workflows/operator_release.yaml#L230){:target="\_blank"} pipeline

```
ansible-playbook -i localhost, -e ansible_connection=local \
upstream/local.yml \
--tags reset_tools,operator_info \
-e run_upstream=true \
-e run_prepare_catalog_repo_upstream=true \
-e catalog_repo=https://github.com/redhat-openshift-ecosystem/community-operators-pipeline -e catalog_repo_branch=main \
-e operator_base_dir=/tmp/community-operators-for-catalog/operators \
-e operators=auqa,cockroachdb \
-e cluster_type=ocp \
-e strict_cluster_version_labels=true \
-e production_registry_namespace=quay.io/community-operators-pipeline 
```

|Name| Description |
|----|----|
|`ansible-playbook -i localhost, -e ansible_connection=local` | ansible command used in local run |
|`upstream/local.yml` | path to main playbook `local.yaml` in `upstream` dicrectory|
|`--tags reset_tools,operator_info` | `reset_tools` tag to install tools and `operator_info` to produce file contains info about operators|
|`-e run_upstream=true` | flag that upstream version is used |
|`-e run_prepare_catalog_repo_upstream=true` | flag that project and branch (see row bellow ) will be clonned to `/tmp/community-operators-for-catalog` |
|`-e catalog_repo=... -e catalog_repo_branch=...` | repo and branch that operators are stored|
|`-e operator_base_dir=/tmp/community-operators-for-catalog/operators` | path where operators are taken|
|`-e operators=auqa,cockroachdb` | list of operators to be processed|
|`-e cluster_type=ocp` | cluster type to be used (`k8s` or `ocp`)|
|`-e strict_cluster_version_labels=true` | flat that cluster version is checked |
|`-e production_registry_namespace=quay.io/community-operators-pipeline` | registry/namepace used for bundles already published to be combined for index |

### Switch K8S and OCP

One can switch between Kubernetes (k8s) and Openshift (ocp) setup by setting the value in [Upgrade](/project/maintain/#github-action-ci-upgrade){:target="\_blank"} workflow. This is heavily used in `development` or `staging` projects by testing both scenarios before putting it in production. 
