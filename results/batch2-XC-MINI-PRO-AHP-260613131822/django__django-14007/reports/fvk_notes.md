# FVK notes — django__django-14007

How the FVK audit was applied to the V1 fix, and the justification for every
decision (each change, and each decision to leave V1 unchanged), traced to
[`fvk/FINDINGS.md`](../fvk/FINDINGS.md) and
[`fvk/PROOF_OBLIGATIONS.md`](../fvk/PROOF_OBLIGATIONS.md).

## What was audited

V1 changed `SQLInsertCompiler.execute_sql` to pass the rows fetched after an
`INSERT … RETURNING` / `last_insert_id` through the field/backend db converters
(`get_converters` + `apply_converters`), mirroring the SELECT path. The FVK
formalization (`fvk/SPEC.md`, `fvk/apply_converters.k`,
`fvk/apply_converters-spec.k`) models the converter-fold core — the triple-nested
loop of `apply_converters`, in the eager form the only caller forces — as a
mini-Python with **uninterpreted** converter application, reducing correctness to
a structural fold equality with one index-in-range side condition.

## Outcome

**V1 is correct against the spec and stands functionally unchanged.** The only
edit applied during the audit is a behaviour-preserving 3-line comment. The
clean, VC-light specification is itself the primary evidence of correctness
(`FINDINGS.md` PF1: no nonlinear VC ever arises).

## Decision log (each traced to the artifacts)

1. **Keep the converter-application logic (the heart of V1).**
   Justified by `FINDINGS.md` **F1** (the bug is precisely that converters were
   never applied on this path) and obligations **OB-CHAIN/OB-ROW/OB-ROWS/OB-APPLY**
   (the loops provably compute `convertRows`, i.e. each returning value becomes its
   converter image — the SELECT-path value). No change.

2. **Keep the `if converters:` short-circuit (return rows unchanged when empty).**
   Justified by **F2** + **OB-NOOP**: for a plain `AutoField`, `get_converters`
   resolves nothing on all four backends, so the guard makes V1 *inert* and
   preserves the exact pre-V1 behaviour (including the `tuple` row type). Removing
   the guard would needlessly map every row to a `list` and add overhead on the hot
   path. No change.

3. **Keep wrapping each field in a `Col` via `field.get_col(opts.db_table)`
   (rather than passing the bare `Field`).**
   Justified by **F4/F5** and **OB-COLRESOLVE/OB-NOATTR**: a `Col` resolves the
   field's own converters (`target == output_field == field`) and supplies both
   `output_field` and `field`, which the backends require — Oracle reads
   `expression.field.empty_strings_allowed`, SQLite/MySQL read
   `expression.output_field`. A bare `Field` would `AttributeError`. The `Col`
   wrapper is load-bearing; keep it. No change.

4. **Keep applying *both* backend and field converters (wider than the literal
   "call `from_db_value`" report).**
   Justified by **F3**: the intent is "the inserted value equals the value a SELECT
   would yield," and the SELECT path composes `backend_converters +
   field_converters`. Applying only `from_db_value` would leave insert/select
   inconsistent for any field with a backend converter. The broader behaviour is
   required, not scope creep. No change.

5. **Do NOT add a defensive index/length guard around `row[pos]`.**
   Justified by **F9** + **OB-INDEX** + UP-1 (`ITERATION_GUIDANCE.md`): the
   soundness side condition `PRE-INDEX` (every converter position indexes a valid
   column) already holds because converter keys are `0..len(returning_fields)-1`
   and each raw row has exactly that many columns (`OB-RAWSHAPE`,
   `return_insert_columns` ordering). A guard would only ever mask an unsupported
   custom-field misconfiguration whose RETURNING SQL is already malformed. No
   change.

6. **Add a 3-line clarifying comment above the converter step (the one edit).**
   Justified by **F1** + **OB-NOOP**: the conversion is the entire fix yet is
   non-obvious, and a future "simplifying" refactor could silently drop it and
   reintroduce F1. The comment documents *why* the step exists. It is
   behaviour-preserving, so every proof obligation holds verbatim. This is the
   "minimal refactor" the task permits, and the audit motivates it.

7. **Do not pursue the Oracle RETURNING-INTO rawness question.**
   Justified by **F11** + **OB-ORACLE-RAW**: it is a semantics-adequacy
   (capability) gap, not a code bug, and is moot for the only standard returning
   field (`AutoField`, which resolves no converter). Marked `[ESCALATION BOUNDARY]`,
   not admitted `[trusted]`. No change.

8. **Accept partial correctness (termination not proved).**
   Justified by **PF3** + **OB-TERM**: the loops iterate finite materialized lists
   (`cursor.fetchall()`, `list(converters.items())`, finite chains), so termination
   is trivially true; proving it adds nothing. No change.

## The actual diff this pass

`repo/django/db/models/sql/compiler.py`, inside `SQLInsertCompiler.execute_sql`,
immediately before `cols = [...]`:

```python
        # Pass the returned values through the fields' database converters (e.g.
        # from_db_value), as the SELECT path does, so an inserted value such as a
        # primary key is the same Python object a query would have returned.
```

No other source changes. The V1 logic (hoisted `opts`, the three `rows = …`
branches, `cols`/`get_converters`/`apply_converters`) is retained exactly.

## Residual risk (from `fvk/PROOF.md §7`)

Constructed, not machine-checked — run the `kompile`/`kprove` commands in
`fvk/PROOF.md §5` to upgrade to machine-verified and unlock the conditional
test-removal recommendations. Trusted base: mini-X adequacy, the reachability
metatheory + `kprove`, Z3/`[simplification]`, and `OB-RAWSHAPE` (the DBMS/driver
returns one column per returning field, in order — identical to pre-V1
assumptions). One named escalation item (`OB-ORACLE-RAW`), moot for `AutoField`.
