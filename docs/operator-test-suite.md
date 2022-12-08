# Operator tests

## Running tests
Run tests by entering 'community-operators' project directory and run following command using options bellow. '<git repo>' and '<git branch>' options are optional.
```
cd <community-operators>
OPP_PRODUCTION_TYPE=<k8s/ocp> \
OPP_DEBUG= 1 \
OPP_AUTO_PACKAGEMANIFEST_CLUSTER_VERSION_LABEL=1 \
OPP_RELEASE_INDEX_NAME="catalog_tmp" \
bash <(curl -sL https://raw.githubusercontent.com/redhat-openshift-ecosystem/community-operators-pipeline/ci/latest/ci/scripts/opp.sh) \
<test-type1,test-type2,...,test-typeN> \
<operator-version-dir-relative-to-community-operators-project> \
[<git repo>] [<git branch>]
```

### Test type

List of tests are shown in following table :

| Test type | Description |
| :-------- |:---------- |
| kiwi | Full operator test |
| lemon | Full test of operator to be deployed from scratch |
| orange | Full test of operator to be deployed with existing bundles in quay registry |
| all | kiwi,lemon,orange |

### Default valus for test

By default `OPP_PRODUCTION_TYPE=k8s` with `OPP_K8S_PRODUCTION_VERSION_DEFAULT=latest` index version is tested. For Openshift test read bellow. 

Followig example will run default `k8s` `lemon` test that would produce FBC (File Based Index) image with tag `latest`
```
bash <(curl -sL https://raw.githubusercontent.com/redhat-openshift-ecosystem/community-operators-pipeline/ci/latest/ci/scripts/opp.sh) \
lemon \
operators/aqua/1.0.2
```

### OCP test and index versions
!!! note
    With variable `OPP_PRODUCTION_TYPE=ocp` Openshift test will be run and `v4.9-db` will be as default version. This can be controled by variable `OPP_OCP_PRODUCTION_VERSION_DEFAULT=v4.9-db` or adding it to test name `orange_v4.9-db`. More info about versions are bellow

| Index | Description |
| :-------- |:---------- |
| v4.9 | v4.9 in FBC(File Based Catalog) format |
| v4.9-db | v4.9 in old sql format |

Followig example will run default `ocp` `lemon` test that would produce DB (old DB index format ) image with tag `v4.9`
```
OPP_PRODUCTION_TYPE=ocp OPP_OCP_PRODUCTION_VERSION_DEFAULT=v4.9-db \
bash <(curl -sL https://raw.githubusercontent.com/redhat-openshift-ecosystem/community-operators-pipeline/ci/latest/ci/scripts/opp.sh) \
lemon \
operators/aqua/1.0.2
```
one can use following as equivalent (to omit `OPP_OCP_PRODUCTION_VERSION_DEFAULT` variable)

```
OPP_PRODUCTION_TYPE=ocp \
bash <(curl -sL https://raw.githubusercontent.com/redhat-openshift-ecosystem/community-operators-pipeline/ci/latest/ci/scripts/opp.sh) \
lemon_v4.9-db\
operators/aqua/1.0.2
```

### Logs
Logs can be found in `/tmp/op-test/log.out`

### Testing log files
If operator test fails, one can enter to testing container via follwing command. One can substitue 'docker' with 'podman' when supported
```
docker exec -it op-test /bin/bash
```

# Examples

## Running tests from local direcotry
Following example will run 'all' tests on 'aqua' operator with version '1.0.2' from 'operators (k8s)' directory. 'community-operators' project will be taken from local directory one is running command from ($PWD).
```
cd <community-operators>
bash <(curl -sL https://raw.githubusercontent.com/redhat-openshift-ecosystem/community-operators-pipeline/ci/latest/ci/scripts/opp.sh) \
all \
operators/aqua/1.0.2
```

## Running tests from official 'community-operators' repo

Following example will run 'kiwi' and 'lemon' tests on 'aqua' operator with version '1.0.2' from 'community-operators (Openshift)' directory. 'community-operators' project will be taken from git repo 'https://github.com/operator-framework/community-operators' and 'master' branch
```
cd <community-operators>
bash <(curl -sL https://raw.githubusercontent.com/redhat-openshift-ecosystem/community-operators-pipeline/ci/latest/ci/scripts/opp.sh) \
kiwi,lemon \
community-operators/aqua/1.0.2 \
https://github.com/operator-framework/community-operators \
master
```

## Running tests from forked 'community-operators' repo ans specific branch
Following example will run 'kiwi' and 'lemon' tests on 'kong' operator with version '0.5.0' from 'operators (k8s)' directory.'community-operators' project will be taken from git repo 'https://github.com/Kong/community-operators' and 'release/v0.5.0' branch ('https://github.com/Kong/community-operators/tree/release/v0.5.0')
```
cd <community-operators>
bash <(curl -sL https://raw.githubusercontent.com/redhat-openshift-ecosystem/community-operators-pipeline/ci/latest/ci/scripts/opp.sh) \
kiwi,lemon \
operators/kong/0.5.0 \
https://github.com/Kong/community-operators \
release/v0.5.0
```

# Misc

|Name|Description|Default|
|:--------|:----------|:----|
|OP_TEST_DEBUG|Debug level (0-3)|0|
|OP_TEST_CONTAINER_TOOL|Container tool used on host|docker|
|OP_TEST_DRY_RUN|Will print commands to be executed|0|

# Testing operators by Ansible

Documentation for testing is located [here](https://github.com/redhat-operator-ecosystem/operator-test-playbooks/blob/upstream-community/doc/upstream/users/README.md)
