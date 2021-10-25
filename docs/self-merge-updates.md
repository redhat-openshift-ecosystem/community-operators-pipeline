# Publish Operator updates self-sufficiently

Updating a published Operator is done by merging PR in to the main branch [community-operators](https://github.com/operator-framework/community-operators/pulls).

By default only [community-operators](https://github.com/operator-framework/community-operators) maintainers can merge PRs to main branch. They will do so if all validation and deployment tests done as part of the automatic checks running on every PR are successful.

If you want to speed up the process of publishing an update, it is possible to have your PRs automatically merge without reviews by the maintainers. The following criteria needs to be met:

- All GitHub checks are successful and `package-validated ` label is set.
- Operator was successfully installed on Kubernetes or Openshift and `installation-validated` label is set.
- You are part of the `reviewer` group for the Operator in question ([more info](./operator-ci-yaml.md#reviewers)) Then and `authorized-changes` label is set.
- If you are updating an already published Operator, only minor (cosmetic) changes are done ([more info](./operator-version-strategy))
- No `do-not-merge/hold `, nor `do-not-merge/work-in-progress` label is set.
- Issue cannot be in draft mode

If those criteria are fulfilled the PR will be automatically merged.

## Preventing automatic merging
You can have a reason to prevent automatic merge. Just post `/hold` command/comment.
Once your changes are final, post `/hold cancel` command/comment. Tests will be restarted and if all conditions stated above are met, merging automatically.

## How do I set up reviewers?

Learn more [here](./operator-ci-yaml.md#reviewers). Remember that modifications to `ci.yaml` need to be reviewed by current reviewers or the maintainers (if no reviewers exist). Every time `ci.yaml` is checked for reviewers, we are checking from `operator-framework/community-operators` default branch. So reviewers should be added in a separate PR in advance.

## How do i approve PR? 
### Auhtor is in reviewer list
In this case `authorized_label` is set automatically and PR will be automerged when all tests will pass

### Author is not in reviewer list
In this case reviewer can approved PR by gitlab [PR review mechanizm](https://docs.github.com/en/github/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/about-pull-request-reviews). Since reviewer doesn't have write access to repository it is not possible to set label. But there are some ways to set `authorized_label` label by our pipeline. Reviewer can do following

1. approve
2. `/hold`
3. `/unhold`

or 

1. approve
2. author will push some new changes

or 

1. approve
2. make `draft` Issue
3. `Ready for review`

!!! info "Pipeline will set `authorized_changes` label only if last github reviewer is in reviewer list (defined in `ci.yaml`) and review state is `APPROVED`"
