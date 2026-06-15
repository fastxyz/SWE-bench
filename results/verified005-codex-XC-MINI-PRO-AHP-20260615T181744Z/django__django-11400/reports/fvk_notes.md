# FVK Notes

## Decisions

### Refined V1 ordering predicate

Changed `RelatedFieldListFilter.field_admin_ordering()` from V1's truthiness check:

```python
if ordering:
```

to:

```python
if ordering is not None and ordering != ():
```

Reasoning trace:

- `fvk/FINDINGS.md` F1 identifies that V1 fixed the reported issue but used a looser predicate than Django's adjacent admin helper.
- `fvk/PROOF_OBLIGATIONS.md` PO4 requires preserving explicit custom non-`()`, non-`None` ordering values.
- `fvk/SPEC.md` evidence E6 cites `ModelAdmin.get_field_queryset()` as the local compatibility rule.

### Kept V1's shared helper structure

Kept `field_admin_ordering()` as the shared resolver for `RelatedFieldListFilter` and `RelatedOnlyFieldListFilter`.

Reasoning trace:

- `fvk/FINDINGS.md` F2 confirms the related filter bug is discharged when empty or missing admin ordering falls back to `Meta.ordering`.
- `fvk/FINDINGS.md` F3 confirms the related-only bug is discharged when the same resolver is passed into `get_choices()`.
- `fvk/PROOF_OBLIGATIONS.md` PO1, PO2, and PO3 require exactly this shared ordering-resolution behavior.

### Kept RelatedOnlyFieldListFilter's choice restriction unchanged

Kept the existing `pk_qs` computation and `limit_choices_to={'pk__in': pk_qs}` argument, adding only `ordering=ordering`.

Reasoning trace:

- `fvk/FINDINGS.md` F3 records the related-only fix and confirms the restriction remains part of the expected behavior.
- `fvk/PROOF_OBLIGATIONS.md` PO5 requires preserving the related-only choice restriction.
- `fvk/SPEC.md` evidence E7 identifies the pre-existing restriction as a frame condition.

### Did not change Field.get_choices()

Left `Field.get_choices()` unchanged and fixed only the admin filter callers.

Reasoning trace:

- `fvk/SPEC.md` intent item 6 scopes the fix to admin filters and avoids a broad behavior change in model fields.
- `fvk/FINDINGS.md` F4 classifies full ORM/database ordering as outside the mini-K fragment and recommends keeping integration tests.
- `fvk/PROOF_OBLIGATIONS.md` PO7 keeps the formal abstraction focused on the ordering argument selected by admin filters.

### Did not run tests or K tooling

No tests, Python commands, `kompile`, `kast`, or `kprove` were run.

Reasoning trace:

- `fvk/FINDINGS.md` F5 records the process constraint.
- `fvk/PROOF_OBLIGATIONS.md` PO8 requires recording commands rather than executing them.
- `fvk/PROOF.md` labels the result "constructed, not machine-checked" and lists the commands for later reproduction.

## Result

V2 differs from V1 by one predicate refinement in `repo/django/contrib/admin/filters.py`. The rest of V1 stands because the FVK obligations show it directly satisfies the public issue intent while preserving the related-only choice restriction and avoiding unrelated global changes.
