# How to document

## Overview
Documentation is published as `mkdocs` which is an extension to the markdown format.

## Documentation location
Public-facing documentation is located at 

- [https://redhat-openshift-ecosystem.github.io/community-operators-prod/](https://redhat-openshift-ecosystem.github.io/community-operators-prod/)
- [https://k8s-operatorhub.github.io/community-operators/](https://k8s-operatorhub.github.io/community-operators/)
- [https://redhat-openshift-ecosystem.github.io/community-operators-pipeline/](https://redhat-openshift-ecosystem.github.io/community-operators-pipeline/)

## Where to edit a documentation

User and maintainer documentation is at [https://github.com/redhat-openshift-ecosystem/community-operators-pipeline/tree/documentation](https://github.com/redhat-openshift-ecosystem/community-operators-pipeline/tree/documentation)

Admin documentation is located at [https://github.com/redhat-openshift-ecosystem/community-operators-pipeline/tree/documentation-admin](https://github.com/redhat-openshift-ecosystem/community-operators-pipeline/tree/documentation-admin)

## How to publish a documentation
No need to publish documentation manually. It is automatically rendered overnight. If there is some urgent case and you need to publish documentation, please restart a `Documentation` workflow

- OCP documentation workflow [https://github.com/redhat-openshift-ecosystem/community-operators-prod/actions/workflows/documentation.yaml](https://github.com/redhat-openshift-ecosystem/community-operators-prod/actions/workflows/documentation.yaml)
- K8S documentation workflow is at [https://github.com/k8s-operatorhub/community-operators/actions/workflows/documentation.yaml](https://github.com/k8s-operatorhub/community-operators/actions/workflows/documentation.yaml)

Or for admin documentation use `Documentation admin` workflow at [https://github.com/redhat-openshift-ecosystem/community-operators-pipeline/actions/workflows/documentation.yaml](https://github.com/redhat-openshift-ecosystem/community-operators-pipeline/actions/workflows/documentation.yaml)

By restarting the last workflow you immediately release an actual documentation version

## Mkdocs image
The image for `mkdocs` is located at [quay.io/operator_testing/community-operators-mkdocs:latest](quay.io/operator_testing/community-operators-mkdocs:latest).
No need to build an image manually, but for a complete picture it is good to know that a corresponding Dockerfile is located at [https://github.com/redhat-openshift-ecosystem/community-operators-pipeline/blob/documentation/Dockerfile.mkdoc](https://github.com/redhat-openshift-ecosystem/community-operators-pipeline/blob/documentation/Dockerfile.mkdoc)

To build the image the following command can be executed:

`podman build -f Dockerfile.mkdoc -t quay.io/operator_testing/community-operators-mkdocs:latest .`