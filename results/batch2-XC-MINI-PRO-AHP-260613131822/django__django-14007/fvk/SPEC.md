# SPEC — django__django-14007 (V1 fix audit)

**Target.** `SQLInsertCompiler.execute_sql()` in
`repo/django/db/models/sql/compiler.py` (lines ~1403–1430 after the V1 fix), and
the two helpers it now reuses on the insert-returning path,
`SQLCompiler.get_converters()` and `SQLCompiler.apply_converters()`
(lines ~1100–1119).

**Status of the formal artifacts.** *Constructed, not machine-checked* — the FVK
MVP does not run `kompile`/`kprove`. The K fragment and claims live in
[`apply_converters.k`](apply_converters.k) and
[`apply_converters-spec.k`](apply_converters-spec.k); the run-commands are in
[`PROOF.md`](PROOF.md). The Findings (benefit 2) do **not** depend on the machine
check and are stated with full confidence.

---

## 1. Intent (from `benchmark/PROBLEM.md`)

> Database converters (`from_db_value`) are not called for `returning_fields` on
> insert. A field whose `from_db_value` wraps the value (e.g. `MyIntWrapper`)
> returns the wrapper on a normal `SELECT` (`AutoModel.objects.first().id`) but a
> bare `int` straight after `create()` / `bulk_create()`.

So the **intended behaviour** is: the value placed on the model attribute for each
returning field after an insert must be the *same* Python-domain value a `SELECT`
would have produced for that column — i.e. the raw database value passed through
that field's database converters (backend converters **then** `from_db_value`),
exactly as the read path does in `results_iter`.

## 2. The V1 implementation under audit

```python
def execute_sql(self, returning_fields=None):
    assert not (returning_fields and len(self.query.objs) != 1 and
                not self.connection.features.can_return_rows_from_bulk_insert)
    opts = self.query.get_meta()
    self.returning_fields = returning_fields
    with self.connection.cursor() as cursor:
        for sql, params in self.as_sql():
            cursor.execute(sql, params)
        if not self.returning_fields:
            return []
        if self.connection.features.can_return_rows_from_bulk_insert and len(self.query.objs) > 1:
            rows = self.connection.ops.fetch_returned_insert_rows(cursor)
        elif self.connection.features.can_return_columns_from_insert:
            assert len(self.query.objs) == 1
            rows = [self.connection.ops.fetch_returned_insert_columns(cursor, self.returning_params)]
        else:
            rows = [(self.connection.ops.last_insert_id(cursor, opts.db_table, opts.pk.column),)]
    cols = [field.get_col(opts.db_table) for field in self.returning_fields]
    converters = self.get_converters(cols)
    if converters:
        rows = list(self.apply_converters(rows, converters))
    return rows
```

The computational core of the fix is the converter fold inside `apply_converters`
(a triple-nested loop). That is what the K artifacts model in the eager form the
only caller forces, `rows = list(self.apply_converters(rows, converters))`.

## 3. Formal model (mini-X)

[`apply_converters.k`](apply_converters.k) is a minimal mini-Python covering only
the constructs this path uses: assignment, list-copy (`list(row0)`), subscript
read/write (`row[pos]`, `row[pos] = v`), `append`, `for … in <list>:`, `return`,
and an **uninterpreted** converter application `applyC(F,V,E,C)`.

> **Why converters are uninterpreted.** A converter (`from_db_value`, a backend
> converter) is an arbitrary function. We do not model what it computes; we model
> that the code applies *exactly the right converters, in the right order, to the
> right column, for every row*. So correctness is **structural fold-equality**,
> not arithmetic, and there are no nonlinear VCs.

## 4. Contracts

### 4.1 `apply_converters` — the function contract `(APPLY)`

Spec functions (closed forms), defined in `apply_converters-spec.k`:

- `applyChain(convs, v, e, c)` — fold the converter chain `convs` left-to-right
  over `v` (inner loop).
- `convertRow(row, entries, c)` — for each entry `(pos, convs, expr)`, replace
  `row[pos]` with `applyChain(convs, row[pos], expr, c)` (middle loop).
- `convertRows(rows, entries, c)` — `convertRow` every row independently (outer
  loop).

**Contract.** For every `rows` and every `converters` such that **every row is
long enough for every converter position** (`allRowsPositionsInRange`),

```
list(apply_converters(rows, converters))  ==  convertRows(rows, converters, connection)
```

i.e. each output row equals the input row with exactly the converter-mapped
columns folded, and **all other columns identical**. In particular, when
`converters` is empty, `convertRows(rows, {}, c) == rows` — the **no-op /
backward-compatibility** case.

### 4.2 `get_converters(cols)` — the converter-resolution contract

For `cols = [field.get_col(opts.db_table) for field in returning_fields]`,
`get_converters` returns a **dict** `{ i : (backend_convs_i + field_convs_i, col_i) }`
keyed by the position `i` of each returning field that has any converter, where

- `field_convs_i = [field_i.from_db_value]` iff `field_i` defines `from_db_value`
  (via `Col.get_db_converters → output_field.get_db_converters`), and
- `backend_convs_i = connection.ops.get_db_converters(col_i)`.

Two structural facts make this well-typed and correct (see Findings F4, F5):

- `field.get_col(opts.db_table)` yields a `Col` with `target == output_field ==
  field`, so `col.get_db_converters(conn)` delegates to
  `field.get_db_converters(conn)` and `col.output_field`/`col.field` exist
  (required by every backend `get_db_converters`, incl. Oracle's
  `expression.field.empty_strings_allowed`).
- the dict keys are **distinct positions** `0..n-1`, one per returning field.

### 4.3 `execute_sql` — the composed contract

Let `rawrows` be the rows fetched from the cursor (one per inserted object, each a
sequence with one value per returning field, in `returning_fields` order — the
RETURNING clause is emitted in that order by `return_insert_columns`). Then

```
execute_sql(returning_fields) == convertRows(rawrows, get_converters(cols), connection)
```

so the value handed to `setattr(obj, field.attname, value)` in
`Model._save_table` / `QuerySet.bulk_create` is the converter-image of the raw DB
value — the read-path value. When `returning_fields` is falsy, the result is `[]`
(unchanged, early return).

## 5. Loop circularities

Three loops ⇒ three circularity claims (`apply_converters-spec.k`), each proved by
guarded coinduction and each reusing the inner one as a lemma:

| Claim | Loop | Generalized over | Side condition |
|---|---|---|---|
| `(CHAIN)` | `for conv in convs` | running value `V`, chain suffix `CL` | — (finite list) |
| `(ROW)` | `for ent in converters` | row `R`, entry suffix `CVS` | `positionsInRange(CVS, size(R))` |
| `(ROWS)` | `for row0 in rows` | accumulator `Acc`, row suffix `ROWS` | `allRowsPositionsInRange(ROWS, CVS)` |

The closed-form fold in each postcondition (`applyChain` / `convertRow` /
`convertRows`) plays the role of the classical loop invariant.

## 6. Preconditions & side conditions (the real contract boundary)

1. **`PRE-INDEX` — index-in-range.** Every converter position indexes a valid
   column of every row: `allRowsPositionsInRange(rawrows, converters)`. Holds
   because `get_converters` keys range over `0..len(returning_fields)-1` and each
   raw row has exactly `len(returning_fields)` columns (RETURNING / `last_insert_id`
   parity). This is the soundness side condition that the `(ROW)`/`(ROWS)` claims
   carry — the analogue of `sum`'s `i ≤ n+1`.

2. **`PRE-DISTINCT` — distinct positions.** Converter positions are pairwise
   distinct (dict keys). *Not needed for the loop-equals-`convertRows` claim*
   (the imperative loop and `convertRow` both apply updates sequentially in the
   same order), but needed to read `convertRow` as a *per-column independent map*
   ("column `p`'s final value is `applyChain` of its own raw value"). Guaranteed
   by `converters` being a `dict`.

3. **`PRE-RAW` — values are unconverted.** The fetched values are raw cursor
   output that has not already been passed through these converters, so applying
   them once is correct (no double-conversion). Holds: the values come straight
   from `fetch_returned_insert_rows` / `fetch_returned_insert_columns` /
   `last_insert_id`, with no prior conversion.

## 7. Deliberately abstracted / escalation boundaries

- **Converter semantics** are opaque (`applyC`). Whether a *particular* converter
  is itself correct (e.g. `from_db_value` returns the right wrapper) is the
  field's contract, not `execute_sql`'s; out of scope.
- **The cursor / DBMS** (`as_sql`, `cursor.execute`, the fetch helpers) is the
  trusted boundary; we assume the fetch helpers return one row per object with one
  column per returning field. See `PROOF_OBLIGATIONS.md` OB-RAWSHAPE.
- **Oracle RETURNING-INTO rawness** (does the value need the same converter the
  SELECT path applies?) is a backend-adequacy question, not a code bug; for the
  only standard returning field (an `AutoField`) Oracle resolves **no** converter,
  so it is moot. Flagged as a capability/escalation item, not admitted as trusted.
