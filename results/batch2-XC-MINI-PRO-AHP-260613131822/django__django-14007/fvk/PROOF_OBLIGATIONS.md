# PROOF OBLIGATIONS — django__django-14007 (V1 fix audit)

Every obligation needed to conclude `execute_sql` satisfies the `SPEC.md §4.3`
contract, with its discharge method and status. Tiers follow the FVK recipe:
**Z3** = linear arithmetic; **simplification** = a stated `[simplification]`
lemma; **structural** = K rewriting / list induction via a circularity;
**boundary** = trusted interface or `[ESCALATION BOUNDARY]`.

Legend: ✅ discharged (constructed, not machine-checked) · 🅑 trusted boundary ·
🅔 escalation boundary.

---

## Core reachability claims (structural, via circularities)

**OB-CHAIN — inner loop folds the converter chain.** `(CHAIN)` claim:
`for conv in CL: value = applyC(conv, value, expr, connection)` ends with
`value == applyChain(CL, V, expr, connection)`, for all `V`, `CL`.
- Discharge: guarded coinduction. Genuine `=>⁺` step = `#forLoop` unfold +
  the assignment. Case-split `CL`: `.List` → `value == V == applyChain(.List,V,…)`;
  `ListItem(F) Rest` → after one step `value := applyC(F,V,…)`, invoke `(CHAIN)` at
  `{value := applyC(F,V,…), CL := Rest}` ⇒ `applyChain(Rest, applyC(F,V,…),…) ==
  applyChain(ListItem(F)Rest, V, …)` by the 2nd `applyChain` rule. No VC.
- Status: ✅ structural.

**OB-ROW — middle loop converts one row at every position.** `(ROW)` claim ends
with `row == convertRow(R, CVS, connection)`, requires `positionsInRange(CVS,
size(R))`.
- Discharge: guarded coinduction; reuses **OB-CHAIN** as the inner lemma.
  Case-split `CVS`: `.List` → `row == R == convertRow(R,.List,…)`;
  `ListItem(entry(P,CL,E)) Rest` → `value := row[P]` (needs `0≤P<size(R)`,
  from `positionsInRange`); inner loop ⇒ `value := applyChain(CL,R[P],E,…)`;
  `row[P] = value` ⇒ `row := R[P <- applyChain(CL,R[P],E,…)] =: R1`; invoke
  `(ROW)` at `{row := R1, CVS := Rest}` (its `positionsInRange(Rest, size(R1))`
  follows from `size(R1)==size(R)` and the head fact) ⇒
  `convertRow(R1, Rest, …) == convertRow(R, ListItem(entry(P,CL,E))Rest, …)` by the
  2nd `convertRow` rule.
- Sub-VCs: `0≤P<size(R)` (**OB-INDEX**, Z3); `size(R1)==size(R)`
  (**OB-SIZEUPDATE**); `positionsInRange` tail-monotonicity (Z3 over the predicate).
- Status: ✅ structural + Z3.

**OB-ROWS — outer loop converts every row, accumulating.** `(ROWS)` claim ends with
`result == Acc convertRows(ROWS, CVS, connection)`, requires
`allRowsPositionsInRange(ROWS, CVS)`.
- Discharge: guarded coinduction; reuses **OB-ROW** as a lemma. Case-split `ROWS`:
  `.List` → `result == Acc`; `ListItem(R0) Rest` → `row := list(R0) == R0` (copy);
  middle loop ⇒ `row := convertRow(R0,CVS,…)` (needs `positionsInRange(CVS,
  size(R0))`, the head of `allRowsPositionsInRange`); `append(result,row)` ⇒
  `result := Acc ListItem(convertRow(R0,CVS,…))`; invoke `(ROWS)` at
  `{result := that, ROWS := Rest}` ⇒ `Acc ListItem(convertRow(R0,…))
  convertRows(Rest,…) == Acc convertRows(ListItem(R0)Rest,…)` by the 2nd
  `convertRows` rule + List associativity.
- Sub-VCs: `positionsInRange` head/tail (Z3); **OB-ASSOC**.
- Status: ✅ structural + Z3.

**OB-APPLY — the function contract.** `result=[]; for…; return result` rewrites to
`convertRows(ROWS, CVS, connection)` under `allRowsPositionsInRange(ROWS, CVS)`.
- Discharge: Transitivity — `result := .List`, then the outer loop via **OB-ROWS**
  with `Acc := .List` (`.List convertRows(…) == convertRows(…)`), then `return`.
- Status: ✅ structural.

**OB-NOOP — empty-converters identity (backward compatibility).** `CVS == .List`
⇒ `convertRows(ROWS, .List, c) == ROWS` ⇒ `execute_sql` returns the fetched rows
unchanged. Mirrors V1's `if converters:` short-circuit (which skips
`apply_converters` entirely when `get_converters` is empty).
- Discharge: `convertRow(R,.List,_) => R` and `convertRows` map ⇒ identity, by
  structural rewriting. Confirms Finding F2 (plain `AutoField` ⇒ no behaviour
  change).
- Status: ✅ structural.

## Arithmetic / lemma obligations

**OB-INDEX (PRE-INDEX) — `0 ≤ P < size(R)` for each converter position.**
- Discharge: Z3, given `positionsInRange(CVS, size(R))` from the `(ROW)`
  precondition, itself supplied by **OB-RAWSHAPE** + `get_converters` keying.
- Status: ✅ Z3 (precondition propagated from OB-RAWSHAPE).

**OB-SIZEUPDATE — `size(L[I <- V]) == size(L)`.**
- Discharge: `[simplification]` lemma in `apply_converters-spec.k`. (A functional
  list update rebinds one slot; length is invariant.)
- Status: ✅ simplification.

**OB-ASSOC — List concatenation associativity + `.List` unit.**
- Discharge: builtin to K's `LIST` (associative-commutative-with-unit `_List_`);
  no explicit lemma needed.
- Status: ✅ builtin.

## Interface / structural facts (outside the mini-X, argued in prose)

**OB-RAWSHAPE 🅑 — each fetched raw row has exactly `len(returning_fields)`
columns, one per returning field, in `returning_fields` order.**
- Basis: `return_insert_columns(fields)` emits the RETURNING list in `fields`
  order; `fetch_returned_insert_rows`/`fetch_returned_insert_columns` preserve
  cursor column order; the `last_insert_id` branch yields exactly one column and is
  reached only when `returning_fields == [pk]`. Trusted DBMS/driver boundary.
- Status: 🅑 trusted boundary (consistent with pre-V1 code, which already indexed
  these rows positionally in `base.py`/`query.py`).

**OB-ORDER — `cols[i]` ↔ `row[i]` ↔ `returning_fields[i]`.**
- Discharge: `cols` is built in `returning_fields` order; `get_converters` keys by
  `enumerate` index; OB-RAWSHAPE pins row column order. ⇒ converter `i` applies to
  field `i`'s column.
- Status: ✅ structural (relies on OB-RAWSHAPE).

**OB-COLRESOLVE — `field.get_col(opts.db_table)` yields a `Col` whose
`output_field == target == field`, so resolved converters are `field`'s.**
- Discharge: read of `Field.get_col`/`cached_col` and `Col.get_db_converters`
  (`target == output_field` branch ⇒ `output_field.get_db_converters`). The alias
  is irrelevant — the `Col` is never compiled to SQL, only queried for converters.
- Status: ✅ structural (code reading).

**OB-NOATTR — no `AttributeError` on any backend's `get_db_converters(col)`.**
- Discharge: `Col` provides `output_field` (ctor) and `field`
  (`Expression.field` property → `output_field`); covers SQLite/MySQL
  (`output_field`) and Oracle (`field`). See Finding F5.
- Status: ✅ structural (code reading).

**OB-DISTINCT (PRE-DISTINCT) — converter positions pairwise distinct.**
- Discharge: `get_converters` returns a `dict`; keys are unique by construction.
- Status: ✅ structural. (Needed only for the per-column-independence *reading*; the
  loop-equals-`convertRows` proof does not depend on it — see SPEC §6.2.)

**OB-NODOUBLE (PRE-RAW) — values are unconverted before `apply_converters`.**
- Discharge: values originate from the fetch helpers with no prior conversion;
  applying the converter chain once is therefore correct (no double application).
- Status: ✅ structural (data-flow reading).

**OB-CONSUMER — callers tolerate `list` rows.** `base.py:874` and
`query.py:506/520` consume rows by positional `zip`, type-agnostic.
- Status: ✅ structural (code reading). See Finding F7.

## Capability gaps

**OB-ORACLE-RAW 🅔 — Oracle RETURNING-INTO value is at the same conversion stage as
a SELECT value.** Beyond the opaque-converter mini-X; needs real Oracle-in-K.
Moot for `AutoField` (no converter resolved). **Not** admitted `[trusted]`.
- Status: 🅔 escalation boundary. See Finding F11.

## Termination (partial-correctness default)

**OB-TERM — the three loops terminate.** Each iterates a finite materialized list
(`cursor.fetchall()`, `list(converters.items())`, a finite converter chain).
- Discharge: *not proved* under the partial-correctness default; trivially true by
  finiteness. Recommendation-only.
- Status: ⏸ not pursued (benign; see Finding PF3).

---

### Summary

| Obligation | Method | Status |
|---|---|---|
| OB-CHAIN / OB-ROW / OB-ROWS / OB-APPLY | circularity + structural | ✅ |
| OB-NOOP (backward compat) | structural | ✅ |
| OB-INDEX | Z3 (from OB-RAWSHAPE) | ✅ |
| OB-SIZEUPDATE | simplification | ✅ |
| OB-ASSOC | builtin | ✅ |
| OB-ORDER / OB-COLRESOLVE / OB-NOATTR / OB-DISTINCT / OB-NODOUBLE / OB-CONSUMER | code reading | ✅ |
| OB-RAWSHAPE | trusted DBMS/driver boundary | 🅑 |
| OB-ORACLE-RAW | escalation (real Oracle-in-K) | 🅔 |
| OB-TERM | finiteness, not pursued | ⏸ |

No obligation is **blocked** in a way that indicates a code bug. The single
escalation item (OB-ORACLE-RAW) is a semantics-adequacy gap that does not affect
the standard returning field.
