# Project development structure

## TODO
- Explain that it is in 3 parts (project+ playbooks+ framework(workflows))
- add main brach to `Producion operator repositories` table
- explain opp.sh and point to function where it desides what ansible arguments to use
- what happen when dev is changed to latest (only workflows changes) and in latest playbook image (latest) is generated
- Staging vs prod (dev vs latest in image) point to config file
- how to produce dev playbook image
- Switch k8s and ocp in staging
- 


# Development
The staging environment is located at [https://github.com/redhat-openshift-ecosystem/community-operators-pipeline](https://github.com/redhat-openshift-ecosystem/community-operators-pipeline) prject. It can simulate stable and development setup. The 

| Name | Project| Barnches |
|------|--------|---------------|
|Framework|[https://github.com/redhat-openshift-ecosystem/community-operators-pipeline](https://github.com/redhat-openshift-ecosystem/community-operators-pipeline)|`ci/latest` and `ci/dev`|

## `ci/dev` vs `ci/latest`

## `upstream-community-dev` vs `upstream-community`
### How to trigger playbook image build
### Custom de image from custom branch
There is also an option to use your own branch `upstream-community-dev-<SOMETHING>`. Then you can trigger playbook `dev` image build the same way as described above.

## Playbook image build
