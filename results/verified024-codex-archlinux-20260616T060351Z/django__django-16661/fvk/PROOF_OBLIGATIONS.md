# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Preserve `limit_choices_to` early allowance

For any `(lookup, value)` matching
`widgets.url_params_from_lookup_dict(fk_lookup).items()`, `lookup_allowed()`
returns `True` before relation-path validation.

Source evidence: docs for `lookup_allowed()` and existing source comments.

V1 status: unchanged. The V1 edit occurs after this early return.

## PO2: Preserve local-field and direct-relation allowance

If the target-field-collapsed relation path has length `0` or `1`,
`lookup_allowed()` returns `True`.

Source evidence: docs say local fields are allowed; existing code comment says
direct values already found through the local relation should remain allowed.

V1 status: unchanged. The `if len(relation_parts) <= 1: return True` branch is
unchanged.

## PO3: Accept the actual configured list-filter path

For any in-domain lookup whose resolved field path is exactly a configured
`list_filter` path, `lookup_allowed()` returns `True`, even if the collapsed
path differs because an intermediate primary-key field is itself relational.

Formal instance:

```text
actual_parts = ["restaurant", "place", "country"]
collapsed_parts = ["restaurant", "country"]
valid_lookups = {"restaurant__place__country"}
candidates contains join(actual_parts)
therefore result = True
```

V1 status: satisfied by adding `field_parts` and
`LOOKUP_SEP.join(field_parts)` to `valid_lookup_candidates`.

Findings: F1.

## PO4: Accept trailing target-field aliases for configured filters

For any lookup whose resolved field path is a configured `list_filter` path
followed only by one or more target fields of the immediately previous
relations, `lookup_allowed()` returns `True`.

Formal instance:

```text
actual_parts = ["restaurant", "place", "country", "id"]
target(country) = id
strip_target_suffixes(actual_parts) contains
    ["restaurant", "place", "country"]
valid_lookups = {"restaurant__place__country"}
therefore result = True
```

V1 status: satisfied by the loop that strips trailing target fields from
`field_parts` and adds each stripped prefix to `valid_lookup_candidates`.

Findings: F2 and F3.

## PO5: Reject real fields beyond the configured filter path

For any lookup that resolves a real non-target field after a configured related
filter path, `lookup_allowed()` returns `False` unless that extended path is
also configured.

Formal instance:

```text
actual_parts = ["restaurant", "place", "country", "name"]
name is not a target field of country
valid_lookups = {"restaurant__place__country"}
candidates =
    {"restaurant__country__name",
     "restaurant__country__name__name",
     "restaurant__place__country__name"}
therefore result = False
```

V1 status: satisfied. The stripping loop stops when the final resolved field is
not a target field of the previous relation.

Findings: F4.

## PO6: Honesty and no-execution obligation

The proof is a constructed artifact only. It must not be represented as
machine-checked, and no test removal is justified in this environment.

V1 status: satisfied by labeling artifacts "constructed, not machine-checked"
and not running tests or tooling.

Findings: F5.
