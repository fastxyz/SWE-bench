# SPEC.md

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 change to `Model._check_ordering()` in `repo/django/db/models/base.py`. The verified unit is the related-ordering path walker inside `_check_ordering()`: for each `Meta.ordering` string containing `__`, it walks resolved field segments and decides whether an unresolved segment is valid as a transform or lookup, or must emit `models.E015`.

The proof abstracts Django model metadata into a sequence of resolution outcomes:

- `field(F)`: the current segment resolved to a model field.
- `missing(Name)`: the current segment did not resolve as a model field.
- Predicates `hasTransform(F, Name)` and `hasLookup(F, Name)` model Django's registered transform and lookup registries for the previously resolved field.

This abstraction preserves the defect axis: whether a final unresolved `isnull` segment registered as a lookup is accepted or rejected by the check.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| I-001 | `benchmark/PROBLEM.md` | "`models.E015` is raised when ordering uses lookups that are not transforms." | `Meta.ordering` validation must accept lookup suffixes that are valid ordering lookups, not only transforms. | Encoded by PO-1 and K claim `FINAL-LOOKUP-VALID`. |
| I-002 | `benchmark/PROBLEM.md` | Error on `'supply__product__parent__isnull'`; `Stock.supply`, `Supply.product`, and `Product.parent` are foreign keys, with `parent` nullable. | A resolved relation path ending in final registered lookup `isnull` must not emit `models.E015`. | Encoded by PO-1 and K claim `REPORTED-CASE`. |
| I-003 | `benchmark/PROBLEM.md` | Both `order_by('...__isnull')` and `order_by('-...__isnull')` are shown as working. | The model check must not reject the same path because of an optional leading `-`. | Encoded by PO-4 as a frame obligation; V1 leaves sign-stripping unchanged. |
| I-004 | Existing source in `Model._check_ordering()` | The pre-existing check accepted `fld.get_transform(part) is not None`. | Registered transforms must remain accepted. | Encoded by PO-2 and K claim `TRANSFORM-STILL-VALID`. |
| I-005 | Existing invalid-model check behavior | Missing fields and missing related fields produce `models.E015`. | The fix must not turn arbitrary missing path segments into valid ordering entries. | Encoded by PO-3 and K claim `NONFINAL-LOOKUP-INVALID`. |
| I-006 | Public API compatibility | `_check_ordering()` is an internal classmethod returning check errors; V1 changes no signature or return type. | No public callsite, override, or producer/consumer shape may be broken. | Encoded by PO-5. |

## Intended Contract

For each ordering component after non-string values, `?`, and a leading `-` are handled by the existing surrounding code:

1. If all path segments resolve as fields, existing validation behavior is preserved.
2. If a segment does not resolve as a field and no prior field exists, emit `models.E015`.
3. If a segment does not resolve as a field and is registered as a transform on the previously resolved field, keep the ordering component valid.
4. If a segment does not resolve as a field, is the final segment, and is registered as a lookup on the previously resolved field, keep the ordering component valid.
5. If a segment does not resolve as a field, is not a transform, and is not a final registered lookup, emit `models.E015`.

## Formal Artifacts

- `fvk/mini-django-ordering.k`: mini semantics for the related-ordering path walker.
- `fvk/ordering-check-spec.k`: K reachability claims for final lookup acceptance, transform preservation, and invalid non-final lookup rejection.
- `fvk/INTENT_SPEC.md`, `fvk/PUBLIC_EVIDENCE_LEDGER.md`, `fvk/FORMAL_SPEC_ENGLISH.md`, `fvk/SPEC_AUDIT.md`, and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`: adequacy and compatibility gate artifacts.

## Verification Commands

These commands are recorded for later machine checking and were not executed in this environment:

```sh
cd fvk
kompile mini-django-ordering.k --backend haskell
kast --backend haskell ordering-check-spec.k
kprove ordering-check-spec.k
```
