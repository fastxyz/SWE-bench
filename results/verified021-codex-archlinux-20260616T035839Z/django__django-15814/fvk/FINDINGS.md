# FVK Findings

Status: constructed, not machine-checked.

## F1: Pre-fix proxy/concrete key split caused the reported crash

Classification: code bug, discharged by V1.

Input: `select_related("custom").only("custom__name")` where `custom` is a
foreign key to `ProxyCustomModel` and `ProxyCustomModel._meta.concrete_model` is
`CustomModel`.

Observed before V1: `deferred_to_data()` recorded the requested `name` field
under `CustomModel` but recorded the required `id` field under
`ProxyCustomModel`. `get_default_columns()` checked concrete field ownership and
selected `name` without `id`. `RelatedPopulator` then raised
`ValueError: 'id' is not in list`.

Expected: the related load mask for `CustomModel` contains both `id` and `name`.

Evidence: `PUBLIC_EVIDENCE_LEDGER.md` entries `E1`, `E2`, `E6`, and `E7`.
Proof obligations: `PO2`, `PO3`, `PO4`, `PO6`.

Resolution: V1 normalizes `cur_model` to `cur_model._meta.concrete_model`
before `opts` and `must_include` are updated.

## F2: V1 satisfies the proxy-only proof obligations

Classification: confirmation, no additional source change justified.

Input: the same proxy relation path.

Observed in V1 by formal model: `buildOnlyMask(anotherModel, proxyCustomModel,
customFk, nameField)` stores `idField` and `nameField` under `customModel`;
`defaultColumns(customModel)` selects both fields.

Expected: `RelatedPopulator` receives an init list containing the primary key
attname.

Evidence: `PROXY-ONLY-PK` and proof obligations `PO2` through `PO4`.

Resolution: no V2 source edit beyond V1.

## F3: Non-proxy behavior remains framed

Classification: compatibility confirmation.

Input: the same path shape with concrete target `CustomModel`.

Observed in V1 by formal model: `concrete(customModel) = customModel`, so the
normalization is an identity and the mask still contains `idField` and
`nameField` for `customModel`.

Expected: no behavior change for non-proxy targets.

Evidence: `CONCRETE-TARGET-FRAME` and proof obligation `PO5`.

Resolution: no V2 source edit.

## F4: Proof and tests are not machine-run in this workspace

Classification: proof capability gap and test gap.

Input: the FVK `.k` artifacts and the Django test suite.

Observed: the task forbids running tests, Python, `kompile`, or `kprove`.

Expected: artifacts must record exact commands and expected outcomes, but no
command may be executed here.

Evidence: task instructions and `PROOF.md`.

Resolution: keep the result labeled "constructed, not machine-checked". Do not
remove tests. Add a regression test only in a setting where test edits are
allowed.

