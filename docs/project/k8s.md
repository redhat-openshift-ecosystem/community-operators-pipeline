# Project maintain

## Overview

The pipeline tests are using [kind](https://kind.sigs.k8s.io/){:target="\_blank"} cluster to test operator installation with local container registry setup.


## Production bundle and catalog locations
{% raw %} 
| Type | Image | Description |
| ----------------- | ------------ |------------ |
| Bundles | [quay.io/operatorhubio/&lt;operator-name&gt;:v&lt;operator-version&gt;](https://quay.io/organization/operatorhubio){:target="\_blank"} | Example: [quay.io/operatorhubio/etcd:v0.9.4](https://quay.io/repository/operatorhubio/etcd?tab=tags){:target="\_blank"} |
| Temporary index (tags) | [quay.io/operatorhubio/catalog_tmp:latest](https://quay.io/repository/operatorhubio/catalog_tmp?tab=tags){:target="\_blank"} | Index contains packages with version same as bundle tag name|
| Temporary index (shas) | [quay.io/operatorhubio/catalog_tmp:latests](https://quay.io/repository/operatorhubio/catalog_tmp?tab=tags){:target="\_blank"}  | Index contains packages with version as bundle sha (used for production)|
| Production index | [quay.io/operatorhubio/catalog:latest](https://quay.io/repository/operatorhubio/catalog?tab=tags){:target="\_blank"} | Multiarch production index image used in `operatorhubio-catalog` seen by OLM|
{% endraw %} 
## Kind cluster and Kubernetes version
By default, the latest k8s version supported by kind is used until the user doesn't limit it via `operatorhub.io/ui-metadata-max-k8s-version` defined in `metadata.annotations` in the CSV file. In case the following value is set `operatorhub.io/ui-metadata-max-k8s-version: "1.21"` then the kind cluster will use Kubernetes latest 1.21 version that kind supports. One can list available Kubernetes versions in [kind project release section](https://github.com/kubernetes-sigs/kind/releases){:target="\_blank"}


