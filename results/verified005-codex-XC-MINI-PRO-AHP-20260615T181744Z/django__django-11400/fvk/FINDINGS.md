# FINDINGS

Status: constructed for FVK audit; not machine-checked.

## F1: V1 fixed the reported paths but used a looser admin-ordering predicate

Classification: code improvement applied in V2.

Evidence:

- V1 returned related admin ordering when `if ordering:` was true.
- `repo/django/contrib/admin/options.py` uses `ordering is not None and ordering != ()` in `ModelAdmin.get_field_queryset()` to decide whether related admin ordering is specified.
- Public issue evidence identifies `()` as the bad no-ordering sentinel.

Concrete case:

- Input state: related admin registered; custom `get_ordering(request)` returns `emptyList`.
- V1 observed behavior: falls back to `Meta.ordering` because an empty list is falsy.
- Expected by adjacent admin predicate: treat values other than `None` and `()` as specified admin ordering, so `emptyList` is passed through.

Resolution:

- V2 changed `if ordering:` to `if ordering is not None and ordering != ():`.

Traces:

- Proof obligations: PO1, PO2, PO4.

## F2: The original RelatedFieldListFilter bug is discharged by V2

Classification: code bug fixed.

Evidence:

- `Field.get_choices()` calls `.order_by(*ordering)`.
- Passing `()` to `.order_by()` clears model default ordering.
- V2 calls `field_admin_ordering()` before `get_choices()` and falls back to `field.remote_field.model._meta.ordering` when no specified related admin ordering exists.

Concrete case:

- Input state: related admin absent or returns `()`, related model has `Meta.ordering`.
- Pre-fix observed behavior: `get_choices(..., ordering=())`, which clears the related model default ordering.
- V2 expected behavior: `get_choices(..., ordering=field.remote_field.model._meta.ordering)`.

Traces:

- Proof obligations: PO1, PO2.

## F3: The original RelatedOnlyFieldListFilter bug is discharged by V2

Classification: code bug fixed.

Evidence:

- The issue says `RelatedOnlyFieldListFilter` omitted the `ordering` kwarg entirely.
- V2 passes `ordering=self.field_admin_ordering(...)`.
- V2 leaves `limit_choices_to={'pk__in': pk_qs}` intact.

Concrete case:

- Input state: related admin defines ordering.
- Pre-fix observed behavior: `get_choices(include_blank=False, limit_choices_to=...)` uses default `ordering=()`.
- V2 expected behavior: `get_choices(..., limit_choices_to=..., ordering=related_admin.get_ordering(request))`.

Traces:

- Proof obligations: PO3, PO5.

## F4: Full database ordering semantics are outside the mini-K fragment

Classification: proof capability / trusted-base gap, not a code bug.

Evidence:

- The formal fragment models the ordering argument selected by admin filters.
- It relies on source evidence that `Field.get_choices()` forwards that ordering to `order_by(*ordering)`.

Residual risk:

- The constructed proof does not model SQL generation, database collation, queryset evaluation, or rendered admin HTML.

Recommended handling:

- Keep integration tests for admin changelist rendering and database ordering.
- Machine-check only the K obligations after installing K; do not remove tests based on this constructed proof alone.

Traces:

- Proof obligations: PO7, PO8.

## F5: No hidden-test or runtime evidence was used

Classification: process constraint.

Evidence:

- No tests, Python, or K tooling were run.
- The audit used only the issue text, V1 notes, source files, and FVK docs allowed by the task.

Traces:

- Proof obligation: PO8.
