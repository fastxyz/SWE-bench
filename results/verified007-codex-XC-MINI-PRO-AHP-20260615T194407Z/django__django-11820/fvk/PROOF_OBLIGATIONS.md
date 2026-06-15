# FVK PROOF OBLIGATIONS

Status: constructed, not machine-checked.

## PO-1: Valid Related `pk` Alias

Precondition: current model `Child` has field `option = relation(Option)`;
`Option.pk.name == 'id'`; `Option` has field `id = scalar`; ordering path is
`option__pk`.

Obligation: `_check_ordering()`'s related-field loop reaches no `models.E015`
for this path.

Reason: discharges Finding F1 and intent evidence E1/E3.

## PO-2: Invalid Related Field Still Errors

Precondition: current model `Child` has field `option = relation(Option)`;
`Option` has no field `missing`; the `option` relation field has no registered
transform named `missing`; ordering path is `option__missing`.

Obligation: `_check_ordering()` appends `models.E015` for the original path.

Reason: preserves invalid-path behavior required by intent evidence E2.

## PO-3: `pk` After Scalar Field Is A Transform, Not A Model Alias

Precondition: current model `Model` has field `test = scalar`; `test` has no
registered transform named `pk`; ordering path is `test__pk`.

Obligation: `_check_ordering()` appends `models.E015` for the original path.

Reason: discharges Finding F2 and prevents the V1 over-acceptance.

## PO-4: Registered Scalar Transforms Remain Accepted

Precondition: current model `Model` has field `test = scalar`; `test` has a
registered transform named `lower`; ordering path is `test__lower`.

Obligation: `_check_ordering()` reaches no `models.E015` for this path.

Reason: preserves existing registered-lookup behavior and public evidence E5.

## PO-5: Frame Conditions

Precondition: ordering entries that do not contain `LOOKUP_SEP`, expressions,
the random ordering marker `?`, direct `pk`, and direct invalid-field checks are
handled by code outside the edited loop.

Obligation: the patch does not change those branches, public method signature,
return type, or error message/id shape.

Reason: satisfies compatibility evidence E6 and keeps the change targeted.

## K Claim Skeletons

The detailed claim skeletons are in `fvk/model-ordering-spec.k`:

- `RELATED-PK-OK` corresponds to PO-1.
- `RELATED-MISSING-E015` corresponds to PO-2.
- `SCALAR-PK-E015` corresponds to PO-3.
- `SCALAR-TRANSFORM-OK` corresponds to PO-4.
- `FRAME-COMPAT` corresponds to PO-5.
