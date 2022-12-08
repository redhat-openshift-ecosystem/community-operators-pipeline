# Orange test fails even when my operator is ok. 
There is one case when your operator is correct, but orange test might fail. This happened when some operator versions are already published and one wants to change
some cosmetic changes to bundle or convert format from `package manifest` to `bundle` format. In these scenarios, one can follow the instruction bellow

- Operator version overwrite
- Operator recreate

## Operator version overwrite
When cosmetic changes are made to an already published operator version `Orange` test will fail. In this case, one needs to have `allow/operator-version-overwrite` label set. One can set it or ask a maintainer to set it for you.

After the PR will be merged, the following changes will happen

- The bundle for a current operator version will be overwritten
- Build catalog with a new bundle

## Operator recreate
When a whole operator is recreated (usually when converting a whole operator from packagemanifest format to bundle format). One needs to have `allow/operator-recreate` label set. One can set it or ask a maintainer to set it for you.

After the PR will be merged, the following changes will happen

- Delete operator
- Rebuild all bundles
- Build the catalog with new bundles
