# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO1 - `values()` writes exact result-shape metadata

Source evidence:

- `repo/django/db/models/query.py:827-833` sets `clone._fields` and `clone.query._fields`.
- `repo/django/db/models/query.py:836-840` sets both `clone._iterable_class` and `clone.query._iterable_class` to `ValuesIterable`.

Formal claim: `VALUES-MARKS`.

Obligation: for any field tuple `F`, `makeValues(F)` produces a query with `hasSelect = true`, `iterable = ValuesIterable`, and `fields = F`.

Status: discharged by one rewrite in the mini semantics.

## PO2 - `values_list()` writes exact variant metadata

Source evidence:

- `repo/django/db/models/query.py:843-872` chooses `NamedValuesListIterable`, `FlatValuesListIterable`, or `ValuesListIterable` and writes the chosen class to `clone.query._iterable_class`.

Formal claims: `VALUES-LIST-TUPLE-MARKS`, `VALUES-LIST-FLAT-MARKS`, `VALUES-LIST-NAMED-MARKS`.

Obligation: for any field tuple `F`, each values-list mode produces a selected query with the corresponding iterable marker and fields `F`.

Status: discharged by one rewrite per mode in the mini semantics.

## PO3 - The `query` setter restores marked selected-query shape

Source evidence:

- `repo/django/db/models/query.py:212-220` checks `value.has_select_fields`, gets `_iterable_class` from the assigned query when present, gets `_fields` from the query when present, and stores `_query`.

Formal claim: `ASSIGN-MARKED-SELECT`.

Obligation: assigning a selected query with marker `(I, F)` to any queryset produces a queryset whose iterable is `I`, whose fields are `F`, and whose query is the assigned query.

Status: discharged by the marked-select setter rewrite.

## PO4 - The `query` setter avoids model iteration for unmarked selected queries

Source evidence:

- `repo/django/db/models/query.py:213-219` uses `value.has_select_fields` and defaults `_iterable_class` to `ValuesIterable` and `_fields` to selected names.
- `repo/django/db/models/sql/query.py:2180-2225` shows selected values queries can be represented by values fields, extra masks, or annotation masks.

Formal claim: `ASSIGN-UNMARKED-SELECT`.

Obligation: assigning a selected query without a marker to any queryset produces a queryset using `ValuesIterable`, not `ModelIterable`.

Status: discharged by the unmarked-select setter rewrite.

## PO5 - Non-selected query assignment preserves existing iterable/field frame

Source evidence:

- V1 only changes state inside `if value.has_select_fields`; outside that branch it stores `_query` as before.

Formal claim: `ASSIGN-NONSELECT-FRAME`.

Obligation: assigning a non-selected query leaves the pre-existing queryset iterable and fields unchanged while replacing the query.

Status: discharged by the non-select setter rewrite.

## PO6 - Metadata survives ORM cloning and pickling boundaries used by the workflow

Source evidence:

- `repo/django/db/models/sql/query.py:295-296` copies `Query.__dict__` in `Query.clone()`.
- The source contains no custom `Query.__getstate__` or `Query.__setstate__`; default Python pickling preserves instance attributes.

Formal representation: the K model treats `Query` as carrying marker fields across the abstract `pickle/unpickle` boundary.

Obligation: a query marker written by `values()` or `values_list()` remains available to the setter after normal clone/pickle/unpickle transitions in the documented same-version workflow.

Status: discharged by source inspection plus model abstraction; not machine-checked.

## PO7 - Exact old/unmarked `values_list()` recovery is underdetermined

Source evidence:

- `Query` state exposes selected columns, but without V1's marker it does not encode tuple/flat/named values-list mode.
- Public hint `benchmark/PROBLEM.md:53` identifies this as the weakness of a `values_select`-only fix.

Formal claim: boundary documented by `ASSIGN-UNMARKED-SELECT`.

Obligation: do not claim exact recovery of values-list variants unless the query carries the marker.

Status: accepted residual limitation; see Finding F4.

