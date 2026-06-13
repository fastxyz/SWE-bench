# FINDINGS — django__django-14007 (V1 fix audit)

Plain-language findings from formalizing `SQLInsertCompiler.execute_sql` and the
converter helpers it now reuses. Each is `input → observed vs expected`. These do
**not** depend on machine-checking the proof (FVK benefit 2). Verdict up front:

> **The V1 fix is correct against the spec, and a *clean* specification exists for
> it (a structural fold with one index-in-range side condition). The clean-spec
> result is itself the strongest signal that the fix is right.** No code bug was
> found; V1 stands. The findings below record what the formalization confirmed and
> the residual/escalation items.

---

## A. The original bug V1 repairs

**F1 — `from_db_value` skipped on the insert-returning path (the reported bug).**
input: a model with `id = MyAutoField(primary_key=True)` whose
`from_db_value` wraps the integer (`MyIntWrapper`); `AutoModel.objects.create()`.
- observed (pre-V1): `am.id == 2` — a bare `int`. `execute_sql` returned the raw
  cursor value and never called any converter, while the SELECT path
  (`results_iter`) does.
- expected (intent §1): `am.id == <MyIntWrapper: 2>` — identical to what
  `AutoModel.objects.first().id` yields.
- root cause: `execute_sql` returned `fetch_returned_insert_*` / `last_insert_id`
  output verbatim, bypassing `get_converters`/`apply_converters`.
- V1: build `cols` from `returning_fields`, resolve converters, and fold them over
  the fetched rows before returning — the `convertRows` contract of `SPEC.md §4.3`.
  Covers `create()`, `save()`, and the `bulk_create()` returning path.

## B. Confirmations that surfaced while writing the spec

**F2 — no regression for a plain `AutoField` (the 99.9% case): zero converters on
every backend.**
input: an ordinary model `id = AutoField(primary_key=True)`; `create()`.
- observed (V1): `get_converters(cols)` returns `{}` ⇒ `if converters:` is false ⇒
  `rows` is returned **unchanged** (same tuples as before V1).
- why: `AutoField` defines no `from_db_value` (so `field_convs == []`), and the
  backend `get_db_converters` resolves nothing for internal types
  `AutoField`/`BigAutoField`/`SmallAutoField`:
  - SQLite — matches only Date/Time/DateTime/Decimal/UUID/Boolean → `[]`;
  - PostgreSQL — no `get_db_converters` override → base `[]`;
  - MySQL — matches only Boolean/DateTime/UUID → `[]`;
  - Oracle — matches only JSON/Text/Binary/Boolean/Date/Time/DateTime/UUID, and
    `IntegerField.empty_strings_allowed is False` → `[]`.
- expected: identical pre/post behaviour for plain AutoFields. **Confirmed.** The
  fix is *inert* unless a returning field actually has a converter.

**F3 — V1 applies *backend* converters too, not only `from_db_value` (wider than
the literal bug report) — and that is the correct choice.**
input: any returning field whose backend resolves a converter (today: none in
core Django, since only `AutoFieldMixin` sets `db_returning=True`, but a 3rd-party
`db_returning` field of, say, `UUIDField` internal type on SQLite would).
- observed (V1): both `backend_converters + field_converters` are applied, in that
  order — exactly as the SELECT path composes them in `get_converters`.
- expected: the post-insert value must equal the post-SELECT value; the SELECT
  path applies *both*, so the insert path must too. A `from_db_value`-only fix
  would leave insert and select inconsistent for such a field.
- verdict: positive finding — the broader behaviour is *required* for the
  intent "same value a SELECT would produce," not scope creep.

**F4 — `field.get_col(opts.db_table)` resolves the right converters.**
input: any returning `field`.
- observed: `get_col` returns a `Col` with `target == output_field == field`
  (its `cached_col` when the alias matches). `Col.get_db_converters` then returns
  `output_field.get_db_converters(conn)` = `[field.from_db_value]` when defined.
- expected: the converter list for column `i` must be the field's own converters.
  **Confirmed.** Passing the bare `field` instead would be wrong (see F5).

**F5 — passing a bare `Field` (instead of a `Col`) would `AttributeError`; the
`Col` wrapper is necessary.**
input: a backend whose `get_db_converters` inspects the expression — SQLite/MySQL
read `expression.output_field.get_internal_type()`; Oracle additionally reads
`expression.field.empty_strings_allowed`.
- observed: a `Field` has **no** `output_field`/`field` attribute, so
  `get_converters([field, …])` would raise. A `Col` supplies both
  (`Col.output_field`, and `Expression.field` is a property returning
  `output_field`). V1 correctly wraps each field in a `Col`.
- expected: no crash on any backend. **Confirmed** the wrapper is load-bearing,
  and that Oracle's extra `expression.field` access is satisfied.

**F6 — the `if expression:` guard in `get_converters` is safe for `Col`.**
input: `cols = [col_0, …]`.
- observed: `BaseExpression`/`Combinable` define neither `__bool__` nor `__len__`,
  so `bool(col)` is always `True`; no column is silently dropped. (The guard
  exists to skip `None` entries in the SELECT path; `cols` here is never `None`.)
- expected: every returning field with converters is processed. **Confirmed.**

**F7 — V1 changes a returned row from `tuple` to `list` *only when converters
run*; this is observationally benign.**
input: a returning field with a converter ⇒ `apply_converters` yields `list` rows.
- observed: both consumers index/iterate positionally —
  `base.py:874 for value, field in zip(results[0], returning_fields)` and
  `query.py:506/520 for result, field in zip(results, db_returning_fields)`.
  `list` and `tuple` behave identically there.
- expected: no consumer relies on the row being a `tuple`. **Confirmed.** When
  there are no converters, V1 deliberately leaves the original `tuple` shape
  untouched (the `if converters:` guard) — maximal backward-compat.

**F8 — ordering is correct: converter position `i` lines up with `row[i]`.**
input: `returning_fields = [pk, …]`.
- observed: `return_insert_columns(fields)` emits the RETURNING column list in
  `fields` order; `fetch_returned_insert_rows`/`_columns` preserve cursor order;
  `cols` is built in `returning_fields` order and `get_converters` keys by that
  enumerate index. So `converters[i]` ↔ `row[i]` ↔ `returning_fields[i]`.
- expected: the converter for a field is applied to that field's column.
  **Confirmed** (no transposition).

## C. Side conditions the proof forced out (the contract boundary)

**F9 — `PRE-INDEX` (index-in-range) is the one soundness side condition.**
The `(ROW)`/`(ROWS)` claims require `positionsInRange` — every converter position
is `< len(row)`. It holds because converter keys are `0..len(returning_fields)-1`
and each raw row has exactly `len(returning_fields)` columns:
- bulk / single RETURNING: one column per returning field;
- `last_insert_id` branch: exactly one column *and* exactly one returning field
  (only the `AutoField` pk has `db_returning=True` on backends without
  `can_return_columns_from_insert`).
input where it *could* fail: a 3rd-party field setting `db_returning=True` on a
backend that does not emit a column for it — then `row` would be shorter than the
converter set and `row[pos]` would `IndexError`. observed: pre-existing breakage
(the RETURNING SQL itself would be malformed), *not introduced by V1*. expected:
documented precondition. → see ITERATION_GUIDANCE UP-1.

**F10 — `PRE-DISTINCT` (distinct positions) holds via the `dict`.**
`get_converters` returns a `dict` keyed by position, so `.items()` has pairwise
distinct positions. This is what lets `convertRow` be read as a per-column
independent map ("each column gets *its own* converter chain"); with a duplicate
position a later entry would clobber an earlier one. Not a risk in V1 — surfaced
as a structural invariant the code relies on.

## D. Residual risk / escalation (capability gaps, NOT code bugs)

**F11 — `[ESCALATION BOUNDARY]` Oracle RETURNING-INTO rawness.**
The mini-X models converters as opaque, so it cannot decide whether a value
returned by Oracle's `RETURNING … INTO` out-param is at the *same* conversion
stage as a SELECT-fetched value (it could already be coerced by cx_Oracle output
handlers). For the only standard returning field, `AutoField`, Oracle resolves
**no** converter (F2), so the question is moot today. If a custom Oracle
`db_returning` field with a backend converter ever existed, faithful resolution
needs a real Oracle-in-K semantics. Routed to escalation; **not** admitted
`[trusted]`.

**F12 — `ignore_conflicts` does not interact with the new code.**
input: `bulk_create(..., ignore_conflicts=True)`.
- observed: `_batched_insert` requests `returning_fields` only when
  `bulk_return and not ignore_conflicts`; single `create()`/`save()` never set
  `ignore_conflicts`. So whenever converters run, the rows are genuine inserted
  rows. No new edge case.

---

## Proof-derived findings from `/verify`

**PF1 — every verification condition is structural or linear; no nonlinear VC.**
Because converters are uninterpreted, the only VCs are (a) `positionsInRange`
linear-arithmetic facts (Z3), (b) `size(L[I<-V]) == size(L)` (one
`[simplification]`), and (c) List-associativity for the outer accumulator
(builtin). The *absence* of a hard arithmetic VC is evidence the fix has no hidden
corner case — contrast `sum`, whose truncating-division VC flagged its `n ≥ 0`
precondition. Classification: **clean spec ⇒ no code bug**.

**PF2 — the proof needs `PRE-INDEX`, and only that.** Being *forced* to add exactly
one side condition (`positionsInRange`), and finding it already guaranteed by the
RETURNING/`returning_fields` column parity, both (a) confirms correctness and
(b) names the precondition a 3rd-party `db_returning` field must respect.
Classification: **needed precondition, already enforced**. UltimatePowers
question → ITERATION_GUIDANCE UP-1.

**PF3 — `apply_converters` is partial-correctness only (termination not proved).**
The loops terminate because `rows`, `converters`, and each chain are finite
materialized lists (`list(converters.items())`, `cursor.fetchall()`), but the
default proof does not establish it. Classification: **termination gap, benign**
(finite inputs). Recommendation: keep, do not pursue total correctness.

**PF4 — no admitted/`[trusted]` claims, one explicit `[ESCALATION BOUNDARY]`
(F11).** The evidence package is honest: everything the bundled tier can discharge
is discharged; the one capability gap is named, not faked.
