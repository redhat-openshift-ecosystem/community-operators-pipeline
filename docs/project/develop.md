# Development

## TODO

- Explain workflow of playbooks and Github Action workflows step by step
- How to fix bug or develop feature
- How to test developemnt changes
- QA
  - How to add comment in PR
  - How to fix error in test or release
  - I want to add label to PR where to change

## How to develop a new feature or fix a bug
1. Initialize an own branch from dev branch
1. Develop a feature or bugfix itself
1. Open a PR against dev branch.
1. Trigger an image build when playbooks were edited or upgrade testing environment when workflows were edited
1. Test the playbook functionality
1. Create a PR against the production branch
1. Wait until an image is produced automatically in case of playbook changes
1. Upgrade production repositories when workflow templates were changed

We will provide more details about some steps below:
### Starting branch

#### Playbook case
 To develop a new feature, a developer has to start from [`upstream-community-dev`](https://github.com/redhat-openshift-ecosystem/operator-test-playbooks/tree/upstream-community-dev) branch in playbooks by creating their own branch. 
 
 Make sure that the development branch `upstream-community-dev` is synchronized with production one `upstream-community`.

#### Workflow case
The development branch which is your base branch is [`ci/dev`](https://github.com/redhat-openshift-ecosystem/community-operators-pipeline/tree/ci/dev). Please make sure that the development branch `ci/dev` is synchronized with the production branch `ci/latest`.

!!! error "Never edit production workflows directly, which are located in `.github/workflows` directory. Your changes will be lost during the next pipeline upgrade - during the next feature implementation."

### PR to dev branch
#### Playbook case
When a feature/bug fix is ready, please open a PR against [`upstream-community-dev`](https://github.com/redhat-openshift-ecosystem/operator-test-playbooks/tree/upstream-community-dev) branch.

There aren't any valid unit tests, just obsolete ones. You can ignore failure there. The only valid test is linting, which should pass.

#### Workflow case
Open a PR against [`ci/dev`](https://github.com/redhat-openshift-ecosystem/community-operators-pipeline/tree/ci/dev) branch.

### Image build trigger

#### Playbook case
To build an image from just edited playbooks, trigger it by GH action called [`Build playbook image`](https://github.com/redhat-openshift-ecosystem/operator-test-playbooks/actions/workflows/playbook_image.yml)

Click `Run workflow` on the top right and select a branch. In this case `upstream-community-dev`.

The functionality allows triggering image build from the feature branch also, however, the naming convention should be like `upstream-community-dev-[something]`.

In both cases (`upstream-community-dev-[something]` and `upstream-community-dev`) your action will produce `quay.io/operator_testing/operator-test-playbooks:dev` image.

#### Workflow case - repo upgrade
No need to build any image. To populate edited workflow templates to the testing project, please execute [Upgrade GH action](https://github.com/redhat-openshift-ecosystem/community-operators-pipeline/actions/workflows/upgrade.yaml). Set branches which you want to test. The standard setup is `ci-dev` and `upstream-community-dev`.

### Test a playbook funkcionality

 To test a currently implemented feature,  one or more test cases need to be set. 
 The only test which is expected to fail is `ci/prow/4.8-pipeline-functionality`. There is a space for improvement to make the test work as a quality gate for Prow job workflow file changes.
 
 Back to tests, we should focus on. We will test the following parts of the test suite:
- Basic PR tests
- Temp index test
- Prow test
- Release test

#### Basic PR tests

To execute all basic PR tests, please edit a description in an operator in the [test pipeline environment](https://github.com/redhat-openshift-ecosystem/community-operators-pipeline/tree/main/operators). Please do not add more operators if not necessary, it can increase the repository size for workflow templates. We recommend editing just a description in an operator. Push to your branch on your own GH repository. Then open a PR. This corresponds with the setup of how contributors work against the community repositories.

#### Prow test
Every PR triggers a Prow test no matter if it is K8S or OCP. This is a standard setup only for `community-operators-pipeline` pipeline. Production pipelines run Prow only if needed. More information on where to find the Prow debug log is [here](https://redhat-openshift-ecosystem.github.io/community-operators-prod/maintainer-documentation/#the-installation-validated-label-is-missing).

#### Temp index test

When prow fails it can be due to a missing temporary index or temporary bundle. Temp index and the bundle are processed by [Prepare Test Index](https://github.com/redhat-openshift-ecosystem/community-operators-pipeline/actions/workflows/prepare_test_index.yaml) workflow. Logs are directly available. If you are not sure to which PR is workflow run related, check `Build temp index and push` stage. You should see something like `Preparing temp index for PR: 347`.

### Release test

When all tests are green, expect `ci/prow/4.8-pipeline-functionality` as mentioned above, we can test release by merging the PR. Then a release can be checked directly [here](https://github.com/redhat-openshift-ecosystem/community-operators-pipeline/actions/workflows/operator_release.yaml), we expect a green result.

### Create a PR against the production branch
Now you are in the phase to create PRs from dev to production for both playbooks and framework:

Open and merge `community-operators-pipeline:ci/dev` to `community-operators-pipeline:ci/latest`. Do not apply it by `Upgrade` procedure next steps are completed to the state that a new playbook image is out.

Open a PR from `operator-test-playbooks:upstream-community-dev` to `operator-test-playbooks:upstream-community`.

### Wait until an image is produced automatically in case of playbook changes

After it is merged, just wait until [`Build playbook image`](https://github.com/redhat-openshift-ecosystem/operator-test-playbooks/actions/workflows/playbook_image.yml) pipeline has finished.

### Upgrade production repositories when workflow templates were changed

Now, it is time to apply workflows by running `CI Upgrade` on [production OCP](https://github.com/redhat-openshift-ecosystem/community-operators-prod/actions/workflows/upgrade.yaml) and [k8s production](https://github.com/k8s-operatorhub/community-operators/actions/workflows/upgrade.yaml).

Failure is not bad if workflows should stay as it is, it just means nothing was changed. If there should be changes, investigate why no change is present.

