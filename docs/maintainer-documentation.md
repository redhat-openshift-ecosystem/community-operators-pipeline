# Maintainer documentation [in progress...]

Community team is responsible for review
- [OCP operators](https://github.com/redhat-openshift-ecosystem/community-operators-prod/pulls)
- [K8S operators](https://github.com/k8s-operatorhub/community-operators/pulls)

Investigation on failed tests can be very complex, but there are also very easy tasks which ublocks majority of PRs.

## Authorized-changes label is missing

Reasons:
- New operator
    - When
        - `new-operator` label is present 
    - What to do
        - Copy content of `clusterserviceversion.yaml` file to https://operatorhub.io/preview and check visually if content looks correct and all fields on the right don’t contain `N/A` except `channel`.


- No reviewer in ci.yaml file
    - When
        - Missing `authorized-changes` label message is displayed.

    - What to do
        - Apply label `authorized-changes`

- Author is not in reviewer list in ci.yaml and ci.yaml file was not modified
    - When
        - `@contributor_name please approve` message is displayed

    - What to do
        - Wait for approval
            - If authorized changes is not set after approval, please one of three options documented [here](https://redhat-openshift-ecosystem.github.io/community-operators-prod/self-merge-updates/#how-can-i-approve-a-pr-against-my-operator).


- Author is not in reviewer list in `ci.yaml` and `ci.yaml` file is modified
    - When
        - ``/ hold Please note that `ci.yaml` was changed`` message is displayed

    - What to do
        - Wait for approval and add `/unhold` if needed.
        - If authorized changes is not set after approval, please one of three options documented [here](https://redhat-openshift-ecosystem.github.io/community-operators-prod/self-merge-updates/#how-can-i-approve-a-pr-against-my-operator)
