# Operator Publishing / Review settings

Each operator might have `ci.yaml` configuration file to be present in operator directory (for example `community-operators/aqua/ci.yaml`). This configuration file is used by [community-operators](https://github.com/operator-framework/community-operators) pipeline to setup various feature like `reviewers` or `operator versioning`.

!!! note
    One can create or modify `ci.yaml` file with new operator version. This operation can be done in the same PR with other operator changes. 

## Reviewers

If you want to accelerate publishing your changes, consider adding yourself and others you trust to the reviewers list. If the author of PR will be in that list, chnages she/he made will be taken as authorized changes (label `authorized-changes` will be set). This will be the indicator for our pipeline that the PR is ready to merged automatically. 

!!! note
    If author of PR is not in `reviewers` list, PR will not be merged automatically. For automatic merging PR needs to have `authorized-changes` label set. Manually or by pipeline finding reviewer in `ci.yaml` on `main` branch. For security reasons we are not checking reviewers from a fork.

!!! note
    If auhor of PR is not in `reviewers` list and `reviewers` are present in `ci.yaml` file. All `reviewers` will be mentioned in PR comment to check for upcomming changes

For this to work, it is required to setup reviewers in `ci.yaml` file. It can be done by adding `reviewers` tag with list of github usernames. For example

### Example
```
$ cat <path-to-operator>/ci.yaml
---
reviewers:
  - user1 
  - user2

```

## Operator versioning
Operators have multiple versions. When a new version is released, OLM can update operator automatically. There are 2 update strategies possible, which are defined in `ci.yaml` at the operator top level.

### replaces-mode
Every next version defines which version will be replaced using `replaces` key in the CSV file. It means, that there is a possibility to omit some versions from the update graph. Best practice is to put them to a separate channel then.

### semver-mode
Every version will be replaced by next higher version according semantic versioning.

### Restrictions
Contributor can decide, if `semver-mode` or `replaces-mode` mode will be used for a specific operator. By default, `replaces-mode` is activated, when `ci.yaml` file is present and contains `updateGraph: replaces-mode`. When a contributor decides to switch and use `semver-mode`, it will be specified in `ci.yaml` file or the key `updateGraph` will be missing.

### Example
```
$ cat <path-to-operator>/ci.yaml
---
# Use `replaces-mode` or `semver-mode`.
updateGraph: replaces-mode
```

## Automatic Cluster Version Label (OCP) - packagemanifest only

Starting OCP v4.9 (based on k8s 1.22) some old API were deprecated ([Deprecated API Migration Guide from v1.22](https://kubernetes.io/docs/reference/using-api/deprecation-guide/#v1-22), [OKD/OpenShift Catalogs criteria and options](./packaging-required-criteria-ocp.md)). User can set `com.redhat.openshift.versions: <versions>` in its bundle annotations.yaml file to limit specific operator version to be visible on certain cluster. Following example will install operator bundle for versions `v4.6, v4.6, v4.8`
```
$ cat <path-to-operators>/<name>/<version/metadata>/annotations.yaml
annotations:
    com.redhat.openshift.versions=v4.6-v4.8
```
For packagemanifest format it is not possible and community-operators pipeline can automatically set such label to the bundle. User have to allow it by putting `packagemanifestClusterVersionLabel: auto` in `ci.yaml` file
```
$ cat <path-to-operator>/ci.yaml
packagemanifestClusterVersionLabel: auto
```