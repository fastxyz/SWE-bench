# FVK Specification for django__django-13315

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

Target under audit:

- `repo/django/forms/models.py::apply_limit_choices_to_to_formfield()`
- Its observable consumers for this issue:
  - `ModelChoiceIterator.__iter__()` renders choices from `field.queryset`.
  - `ModelChoiceField.to_python()` validates a submitted value with
    `self.queryset.get(...)`.

The spec is intentionally scoped to duplicates introduced by applying
`limit_choices_to` to a form field queryset. It does not require this helper to
deduplicate a queryset that was already duplicate before `limit_choices_to` was
applied.

## Intent-Only Specification

I1. A `ForeignKey.limit_choices_to` value may be a `Q` object for complex
queries.

I2. Applying such a limit to a `ForeignKey` form field must not render duplicate
options when the limit condition traverses a join with multiple matching related
rows.

I3. Selecting a value that corresponds to one model object must not make
`ModelChoiceField.to_python()` raise `MultipleObjectsReturned` merely because the
limit condition's join has multiple witnesses for that same object.

I4. The fix must not use a row-wide `DISTINCT` strategy that requires the
database to compare every selected column, because the public issue history
records that such a fix was reverted after breaking custom model fields whose
database values were not comparable.

I5. Existing behavior outside the bug should be preserved: callable
`limit_choices_to` is still invoked by `get_limit_choices_to()`, dict limits and
`Q` limits remain supported, empty limits are a no-op, the public helper
signature is unchanged, and custom formfield querysets remain the outer queryset.

## Public Evidence Ledger

E1. Source: prompt/problem. Quote: "If you pass a Q object as
limit_choices_to on a ForeignKey field involving a join, you may end up with
duplicate options in your form." Obligation: applying a Q-based join limit must
not multiply rendered choices. Status: encoded by PO-1 and PO-2.

E2. Source: prompt/problem. Quote: "This is nasty because it not only renders
duplicates but also blows up when .get() is called on the queryset if you select
one of the duplicates (MultipleObjectsReturned)." Obligation: the same queryset
used for validation must not contain multiple rows for the selected object due
to the limit join. Status: encoded by PO-3.

E3. Source: prompt/problem. Quote: "distinct queries introduced by [15607]
cause errors with some custom model fields" and the copied custom `PointField`
example. Obligation: avoid row-wide distinct/comparison as the deduplication
mechanism. Status: encoded by PO-4.

E4. Source: prompt/problem. Quote: "Documentation on ForeignKey.limit_choices_to
already mentions: 'Instead of a dictionary this can also be a Q object for more
complex queries.'" Obligation: both dictionary and `Q` forms stay in-domain.
Status: encoded by PO-5.

E5. Source: local implementation. `ForeignKey.formfield()` passes
`queryset=self.remote_field.model._default_manager.using(using)` and
`limit_choices_to` to `forms.ModelChoiceField`; `ModelChoiceIterator` and
`ModelChoiceField.to_python()` both consume `field.queryset`. Obligation: fix
the shared queryset, not only rendering. Status: encoded by PO-2 and PO-3.

E6. Source: local implementation. `QuerySet.complex_filter()` accepts a `Q`
object or a dictionary and adds it as a direct filter to the queryset.
Obligation: replacing direct filtering must preserve the accepted limit input
forms. Status: encoded by PO-5.

## Abstract Model

Let `B` be the outer form field queryset before applying a non-empty
`limit_choices_to`. In the intended ForeignKey formfield path, `B` has at most
one row per related model primary key.

Let `L` be the relation represented by `limit_choices_to`. For a base row `r`,
let `witnesses(L, r)` be the number of joined related rows that make `L` true
for `r`.

The legacy direct-join behavior is modeled as:

```
direct(B, L) = concat(repeat(r, witnesses(L, r)) for r in B)
```

The required behavior is:

```
exists_filter(B, L) = [r for r in B if witnesses(L, r) > 0]
```

`exists_filter()` preserves membership while ensuring that `L` contributes at
most one output row for each input row.

## Formal Spec English

S1. If a form field has no queryset, has no `get_limit_choices_to()`, or its
resolved limit is empty, `apply_limit_choices_to_to_formfield()` leaves the
queryset unchanged.

S2. If the resolved limit is a non-empty dictionary, it is interpreted as
`Q(**limit_choices_to)`. If it is already a `Q`, it is used as that condition.

S3. For a non-empty limit, the output queryset is the original outer queryset
filtered by `EXISTS(base_model_row WHERE base_model_row.pk = outer.pk AND L)`.

S4. For any outer queryset `B` with unique primary keys, the output contains
exactly the rows in `B` for which `witnesses(L, row) > 0`, and contains each
such primary key exactly once.

S5. For any selected primary key from the output, the validation queryset has
cardinality one for that primary key, not cardinality greater than one due to
multiple join witnesses.

S6. The implementation does not add `.distinct()` or an equivalent row-wide
comparison requirement to the outer queryset.

S7. The helper signature and the `ModelChoiceField`/widget consumer protocol are
unchanged.

## Adequacy Audit

S1 passes I5: empty/no-applicable-limit behavior is preservation of existing
non-bug behavior.

S2 passes I1, I4, and E6: `Q` remains supported, dictionaries remain supported,
and neither requires row-wide distinctness.

S3 passes I2 and I3: the limit is evaluated as a correlated existence condition
instead of a direct multi-valued join on the outer rows.

S4 passes I2: it states the no-duplicate rendering property over the issue's
cause, not over arbitrary pre-duplicated custom querysets.

S5 passes I3: it covers the `.get()`/`MultipleObjectsReturned` symptom.

S6 passes I4: it explicitly rejects the previously reverted `DISTINCT` family of
fixes.

S7 passes I5: no public signature or consumer protocol is changed.

No formal-English obligation is candidate-derived without public support. The
only narrowing assumption is that the input outer queryset is unique before the
limit is applied; this is a named default-domain assumption for the standard
ForeignKey formfield path and is not used to excuse duplicates introduced by
`limit_choices_to`.

## Compatibility Audit

Changed public symbol: none. The helper body changed, but
`apply_limit_choices_to_to_formfield(formfield)` keeps the same name, arity, and
mutation protocol.

Changed consumer protocol: none. The helper still assigns a `QuerySet`-like
object to `formfield.queryset`, and `ModelChoiceIterator`, widgets, and
`ModelChoiceField.to_python()` continue to consume that queryset normally.

Changed accepted limit forms: none. Callable resolution remains in
`get_limit_choices_to()`. Resolved dictionaries and `Q` objects remain accepted.
Empty limits remain no-op.

Unhandled public callsites or overrides: none found in the audited source path.
