# INTENT SPEC

Status: constructed, not machine-checked.

The public issue requires the migration optimizer to fold same-model
`CreateModel + AlterModelManagers` into a single `CreateModel`, analogous to the
existing `CreateModel + AlterModelOptions` optimization.

Required behavior:

1. Same-model `CreateModel(N, F, O, B, M0)` followed by
   `AlterModelManagers(N, M1)` reduces to one `CreateModel`.
2. The one `CreateModel` has managers `M1`.
3. The one `CreateModel` preserves name `N`, fields `F`, options `O`, and bases
   `B`.
4. Manager alteration replaces the manager list rather than merging with the
   existing list.
5. Different-model `AlterModelManagers` operations are not absorbed.
6. Empty manager lists are valid final manager lists.
