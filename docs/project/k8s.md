# Project maintain

## TODO

- ui max k8s
- latest
- where are bundles

## Overview

The pipeline tests are using [kind](https://kind.sigs.k8s.io/){:target="\_blank"} cluster to test operator installation with local container registry setup.

### Kind cluster and Kubernetes version
By default, the latest k8s version supported by kind is used until the user doesn't limit it via `operatorhub.io/ui-metadata-max-k8s-version` defined in `metadata.annotations` in the CSV file. In case the following value is set `operatorhub.io/ui-metadata-max-k8s-version: "1.21"` then the kind cluster will use Kubernetes latest 1.21 version that kind supports. One can list available Kubernetes versions in [kind project release section](https://github.com/kubernetes-sigs/kind/releases){:target="\_blank"}

### Production bundles and catalog location

