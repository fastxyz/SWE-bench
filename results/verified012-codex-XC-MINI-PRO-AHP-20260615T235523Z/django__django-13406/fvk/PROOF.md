# FVK Proof

Status: constructed, not machine-checked. No K command was executed.

## What Is Proved

The constructed proof establishes partial correctness for the result-shape protocol:

- `values()` creates a selected query carrying `ValuesIterable` and `_fields`.
- `values_list()` creates a selected query carrying the exact tuple, flat, or named iterable class and `_fields`.
- Assigning a marked selected query to a queryset restores the recorded iterable class and fields.
- Assigning an unmarked selected query falls back to `ValuesIterable`, preventing the reported model-instantiation crash.
- Assigning a non-selected query preserves the previous iterable/field frame and replaces the query.

No loops or recursion are involved in this reduced model, so there are no circularity claims.

## Machine-Check Commands

These commands are emitted for a future environment with K installed. They were not run.

```sh
cd fvk
kompile mini-django-query.k --backend haskell
kast --backend haskell django-queryset-query-spec.k
kprove django-queryset-query-spec.k
```

Expected machine-check result if the mini semantics and claims parse and discharge: `#Top`.

## Proof Sketch

### `VALUES-MARKS`

Initial state: `<k> makeValues(F) </k>`.

The `makeValues` rule rewrites directly to `query(true, someIterable(ValuesIterable), someFields(F), F)`. This matches PO1 and the source writes at `repo/django/db/models/query.py:827-840`.

### `VALUES-LIST-*`

Initial states:

- `<k> makeValuesList(F, tupleMode) </k>`
- `<k> makeValuesList(F, flatMode) </k>`
- `<k> makeValuesList(F, namedMode) </k>`

Each mode has a distinct rewrite to a selected query carrying the matching iterable:

- tuple mode -> `ValuesListIterable`
- flat mode -> `FlatValuesListIterable`
- named mode -> `NamedValuesListIterable`

This matches the conditional assignment at `repo/django/db/models/query.py:866-872` and discharges PO2.

### `ASSIGN-MARKED-SELECT`

Initial state:

`<k> assignQuery(qs(OLDI, OLDF, OLDQ), query(true, someIterable(I), someFields(F), SEL)) </k>`

The marked selected-query rule rewrites to:

`qs(I, someFields(F), query(true, someIterable(I), someFields(F), SEL))`

This models `repo/django/db/models/query.py:212-220`: `has_select_fields` enters the branch, `getattr(value, '_iterable_class', ValuesIterable)` returns the marker `I`, `getattr(value, '_fields', ...)` returns `F`, and `_query` is set to the assigned query. This discharges PO3.

### `ASSIGN-UNMARKED-SELECT`

Initial state:

`<k> assignQuery(qs(OLDI, OLDF, OLDQ), query(true, noIterable, noFields, SEL)) </k>`

The unmarked selected-query rule rewrites to:

`qs(ValuesIterable, someFields(SEL), query(true, noIterable, noFields, SEL))`

This models the fallback arguments in `repo/django/db/models/query.py:214-219`. It proves the selected query no longer remains at `ModelIterable`, but it intentionally does not prove exact `values_list()` variant recovery without metadata. This discharges PO4 and records the boundary in PO7/F4.

### `ASSIGN-NONSELECT-FRAME`

Initial state:

`<k> assignQuery(qs(OLDI, OLDF, OLDQ), query(false, MI, MF, SEL)) </k>`

The non-selected rule rewrites to:

`qs(OLDI, OLDF, query(false, MI, MF, SEL))`

This models that V1 only mutates iterable/fields inside the `has_select_fields` branch. This discharges PO5.

## Adequacy Check

The proof distinguishes the defect axis. A failing pre-fix instance maps to `qs(ModelIterable, noFields, selectedQuery)`. The fixed instance maps to `qs(ValuesIterable, someFields(...), selectedQuery)` or the appropriate values-list iterable. Since these are different values in the model, the abstraction can distinguish pass from fail.

The proof does not model SQL row contents. That is acceptable for this issue because the reported crash occurs before row values matter: a selected-values row is routed into the wrong iterable class.

## Test Guidance

No test file was modified. Because the proof is constructed but not machine-checked, no existing tests should be removed.

Recommended tests to keep/add:

- `values().annotate()` query pickle/reassignment yields dictionaries.
- `values_list()` query pickle/reassignment yields tuples.
- `values_list(flat=True)` query pickle/reassignment yields scalars.
- `values_list(named=True)` query pickle/reassignment yields namedtuples.
- annotation-only and extra-only selected values queries avoid `ModelIterable`.

