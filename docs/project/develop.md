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
 
 Make sure that development branch `upstream-community-dev` is synchronized with production one `upstream-community`.

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
