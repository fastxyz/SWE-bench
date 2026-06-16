# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and symbolic reasoning only.

## F1: V1 closes the reported relational primary-key path bug

Input:

```text
model = Waiter
list_filter = {"restaurant__place__country"}
lookup = "restaurant__place__country"
```

Observed before V1: `place` was treated only as a target-field alias of
`restaurant`, producing the collapsed candidate `restaurant__country`; that did
not intersect `list_filter`, so the lookup was disallowed.

Expected: `True`, because the actual field path
`restaurant__place__country` is explicitly configured in `list_filter`.

V1 status: closed. `field_parts` records the actual resolved field path, and
`restaurant__place__country` is included in `valid_lookup_candidates`.

Proof obligations: PO3.

## F2: V1 preserves admin-generated target-field lookup keys

Input:

```text
model = Waiter
list_filter = {"restaurant__place__country"}
lookup = "restaurant__place__country__id__exact"
```

Observed risk: a fix that simply stopped collapsing relational target fields
would reject admin-generated related-filter query keys that append the target
primary-key field.

Expected: `True`, because the key represents the configured related filter path
plus the related target field and lookup suffix.

V1 status: closed. `field_parts` records
`restaurant__place__country__id`; the trailing target field `id` is stripped,
adding `restaurant__place__country` as a valid candidate.

Proof obligations: PO4.

## F3: V1 preserves direct relation target aliases

Input:

```text
model = Waiter
list_filter = {"restaurant"}
lookup = "restaurant__place__exact"
```

Observed risk: a narrow fix for F1 could require `restaurant__place` to be in
`list_filter`, even though the admin related filter for `restaurant` may use the
remote target field `place`.

Expected: `True`, because this is still the direct `restaurant` relation filter
key with a target-field alias.

V1 status: closed. The original collapsed path remains `restaurant`, so
`len(relation_parts) <= 1` returns `True` as before.

Proof obligations: PO2 and PO4.

## F4: V1 does not authorize real fields beyond the configured filter path

Input:

```text
model = Waiter
list_filter = {"restaurant__place__country"}
lookup = "restaurant__place__country__name"
```

Expected: `False`, because `name` is a real field reached after the configured
related filter path and is not itself configured in `list_filter`.

V1 status: closed by symbolic trace. The candidate set contains
`restaurant__country__name`,
`restaurant__country__name__name`, and
`restaurant__place__country__name`; none equals
`restaurant__place__country`.

Proof obligations: PO5.

## F5: Verification is constructed, not machine-checked

Input: all proof obligations.

Observed: this environment forbids running K tooling, Python, or tests.

Expected: do not claim machine-checked proof or remove tests. Record exact
commands for later checking and keep tests.

V1 status: no code change. This is a proof-process limitation, not a source bug.

Proof obligations: PO6.

## Open Code Findings

None. The audit did not find a source-level defect requiring a V2 code edit.
