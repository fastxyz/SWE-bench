# django__django-10554 — FVK artifact failure analysis

**Batch:** `batch1-XC-MINI-PRO-AHP`  ·  **fvk eval:** `resolved=false`  ·  **VERDICT: MISSING (root cause reachable from public data)**

One-line: the gold fix is in `SQLCompiler.get_order_by()` (auto-add an un-aliased ORDER-BY column to the SELECT list instead of raising); the fvk arm formalized and confirmed an entirely different, wrong fix (deep-copy `combined_queries` in `Query.clone()`) and never touched the true region.

---

## 1. Root cause

**Where.** `django/db/models/sql/compiler.py :: SQLCompiler.get_order_by()`, the combinator positional-relabel block, the `for … else:` at ~line 356–359. Secondary: a new helper `Query.add_select_col` in `django/db/models/sql/query.py` (~line 1777).

**Why it's a bug.** For a combined query (`union`/`intersection`/`difference`, `self.query.combinator` set) the generated SQL cannot reference ORDER BY columns by name, so `get_order_by` rewrites each term into a **1-based positional reference** by scanning `self.select` for a matching column. If no match is found, the base code unconditionally raises:

```python
else:
    raise DatabaseError('ORDER BY term does not match any column in the result set.')
```

That `else` collapses two semantically different "not in select" situations into one hard failure: (a) an **aliased / realiased** column that genuinely cannot be satisfied — *should* raise; (b) a **plain, un-aliased** model column that simply wasn't selected — SQL permits ordering by it, so the correct behavior is to **add it to the SELECT** and order by its new position. Case (b) was missing. On the issue's repro (`qs1.union(qs2.order_by('order'))` then `qs.order_by().values_list('pk', flat=True)`), the ordering column drops out of the reduced SELECT and the compiler errors (`ORDER BY position N is not in select list` / the `DatabaseError` raise).

**Correct fix (oracle).** Make the `else` conditional and add the helper:

```python
else:
    if col_alias:
        raise DatabaseError('ORDER BY term does not match any column in the result set.')
    # Add column used in ORDER BY clause without an alias to the selected columns.
    self.query.add_select_col(src)
    resolved.set_source_expressions([RawSQL('%d' % len(self.query.select), ())])
```
```python
def add_select_col(self, col):
    self.select += col,
    self.values_select += col.output_field.name,
```
(`add_select_col` grows both `select` and `values_select` so `values_list()` stays consistent and the positional index is valid.)

**Bug type.** Missing-case / overly-broad error condition (a too-coarse `else: raise` that swallows a valid case); secondary flavor: incomplete combined-query ORDER BY support. It is **not** a state-mutation/aliasing bug — which is exactly what V1 and the fvk arm assumed.

**Public-data reachability — YES.** The public issue gives the repro plus a traceback ending in `compiler.py … execute_sql … cursor.execute(sql, params)`; the public source of `get_order_by` (with its inline comment that combinator columns "can't be referenced by the fully qualified name") contains the offending `raise`. So existence + location are derivable from public data. Notably the public `hints_text` **both lures and warns**: it suggests "a `.query` attribute change without performing a prior `copy()`" (the V1/clone hypothesis) yet immediately records *"Tests aren't passing… we've not hit the right strategy yet"* — i.e. the copy approach was tried and publicly flagged as wrong. The hidden FAIL_TO_PASS tests pin the *precise* contract (the `if col_alias:` half — still raise for aliased columns, confirmed by the PASS_TO_PASS `test_order_raises_on_non_selected_column`) but are not needed to discover the root cause. Evidence: `evidence/public_data_hints.md`, `evidence/oracle_patch.diff`.

**FAIL_TO_PASS (authoritative, from `eval/fvk.report.json`):** `test_union_with_values_list_and_order` and `test_union_with_values_list_on_annotated_and_unannotated` (both `queries.test_qs_combinators.QuerySetSetOperationTests`). Both exercise the auto-add-column path. `test_order_raises_on_non_selected_column` is a **PASS_TO_PASS**, guarding the still-raise-for-aliased branch. (`evidence/eval_fail_to_pass.md`.)

## 2. What the fvk arm did (V1 vs final + key artifact contents)

**V1 = final, cosmetically.** `diff solution_baseline.patch solution_fvk.patch`: both add the *same* block to `Query.clone()` deep-copying `combined_queries`. fvk's only substantive change is a guard-token swap `if self.combinator:` -> `if self.combined_queries:` (behavior-identical) plus a reworded comment. **fvk confirmed V1; it did not relocate the fix.** Neither patch touches `get_order_by`/`add_select_col`. (`evidence/v1_vs_final_diff.md`.)

**Artifacts produced (all present):** `SPEC.md`, `FINDINGS.md`, `PROOF_OBLIGATIONS.md`, `PROOF.md`, `ITERATION_GUIDANCE.md`, and two K files `query_clone.k` / `query_clone-spec.k`. The entire formal apparatus models an **object-aliasing / non-interference** contract for `Query.clone()`:
- `SPEC.md:9-15` fixes the spec target as `Query.clone()` deep-copying `combined_queries`.
- `query_clone.k` models a heap of `obj(cols, comb)` with `clone` (fresh-id deep copy) and `setvals` (in-place column reset); `query_clone-spec.k` states **(CLONE-REC)** disjointness `reach(clone(R)) ∩ reach(R) = ∅` and **(CLONE-ISO)** non-interference `preservedOn(reach(q), …)`.
- `PROOF.md §4` proves V1 yields non-interference *regardless* of `compiler.py:429`; `PROOF_OBLIGATIONS.md` PO-1/3/4/5 discharge freshness, acyclicity, deep-enough-ness.

The proof is fully self-consistent — for the **wrong** property. It never proves anything about ORDER-BY-position validity.

## 3. Artifact audit — VERDICT: **MISSING (reachable)**

The true root cause (`get_order_by` raising on an un-aliased ORDER-BY column not in the SELECT) appears **nowhere** in the artifacts. Confirmed-absence search (across all `fvk/*` files, `reports/fvk_notes.md`, and the full transcript): **zero** occurrences of `get_order_by`, `add_select_col`, the string `'ORDER BY term does not match'`, or compiler.py lines 356/359. Every root-cause-adjacent reference points at the *adjacent-but-wrong* region `get_combinator_sql`/`set_values` (compiler.py:428–430) or at `Query.clone()`.

**The primer's flagged lead is a false positive.** The primer (`fvk-primer.md:148`, tell #4) suggested `django-10554 SPEC.md:31-38` might narrate the root cause as the thing being fixed. It does **not**. Verbatim (`SPEC.md:30-37`):

> The mutation that makes independence matter is in `SQLCompiler.get_combinator_sql()` (`compiler.py:430`): when a combinator query is compiled with a `values()/values_list()` column list, it calls `set_values()` on each combined query to reset its selected columns to the outer column list. If a combined `Query` object is **shared** between the original union and a derived queryset, that reset is visible to both, and the original later emits a reduced column list while its combinator `ORDER BY` still references a (now out-of-range) column position -> `ORDER BY position N is not in select list`.

This quotes the real **symptom string** ("ORDER BY position N is not in select list") but mislocates the **cause** in `get_combinator_sql`/operand-sharing. The actual cause — `get_order_by` refusing to add an un-aliased ordering column — is a different function and a different mechanism. Under the §4 "pointed-at-the-spot" test, a knowledgeable reader pointed here would **not** agree it encodes the faulty thing or the correct-fix direction; it encodes a *plausible alternative theory* that the gold patch does not implement. So this is presence-of-a-wrong-mechanism, not BURIED presence of the right one. (`evidence/fvk_SPEC_lines_9-37.md`.)

**The nearest miss — and why MISSING, not BURIED.** `FINDINGS.md` F7 (lines 85-95) is the one honest hedge that gets close:

> Consequence (honest): With that line present, I could **not** construct a concrete input that reproduces the reported crash purely through the `set_values` path — the combined operands are never mutated in place. … Two readings, both leaving V1 *correct*.

The agent *noticed its own mechanism does not reproduce the bug* — exactly the kind of spec-difficulty signal that should reopen localization (primer tell #5). But it enumerated only two readings, both of which keep V1 correct ("V1 is the decisive fix" / "defense-in-depth"), and never considered that the crash path is elsewhere. This is the §7 inversion: a hard-to-reproduce signal reframed as reassurance. Even closer, `FINDINGS.md` PD-3 (lines 144-150) flags the *adjacent* column-alignment guard at `get_combinator_sql:428` as "an unrelated latent bug, out of scope … separate from #10554" — the agent is staring one function away from the fix and explicitly rules the column/ORDER-BY-alignment area out of scope. Crucially, **none of these is a fingerprint of the actual defect**: there is no `requires`, no PO, no escalation boundary, and no spec claim sitting on the `get_order_by` raise. The three `[ESCALATION BOUNDARY]` markers (`PROOF_OBLIGATIONS.md` PO-8, `PROOF.md §2`, `FINDINGS.md` PD-1) all sit on the heap-disjointness VC of the *wrong* clone proof and are correctly classified as a proof-capability gap, not a code bug.

Because the root cause was **defined out of scope before any obligation was written** — the spec domain was drawn around `Query.clone()` and operand-sharing — no formal artifact carries its fingerprint. That is the §4/§7 signature of **MISSING-but-reachable**, not BURIED. The information FVK generated does not contain the root cause.

**Transcript corroboration (`transcripts/fvk.jsonl.gz`).** The agent twice had the exact gold-fix line on screen and walked past it: msg#20-21 it read `compiler.py` lines 254-473 (which contain the `'ORDER BY term does not match…'` raise) then immediately (msg#23) pivoted to `Query.clone()`; msg#181 it re-read the `get_order_by` docstring ("can add totally new select clauses" — precisely what `add_select_col` does) but chased annotation machinery. `add_select_col` appears 0 times in the transcript. The inherited baseline hypothesis (copy the query) plus the "confirm the V1 fix" framing (msg#250) kept localization closed.

**Headroom: NO** (MISSING-but-reachable does not count toward improvable-headroom; it is recorded as an FVK gap).

## 4. How FVK could surface it (prose, general, no-exec)

The failure is a **scope-capture / confirmation** failure, not a notation gap, so the fix is procedural:

1. **Adversarial reproduction obligation.** When the spec target is a *fix* (V1), FVK should be required to *symbolically reproduce the reported failure on the pre-fix code and show V1 removes it*. Here that obligation is undischargeable through the chosen `set_values` model — the agent even says so (F7) — which should have *forced* the spec domain open instead of being explained away. A standing rule "if you cannot construct the crash via your modeled mechanism, your mechanism is probably not the bug; re-localize" would convert F7 from reassurance into a re-localization trigger (primer tell #5/#7).

2. **Anchor the intent ledger to the traceback frame, not to the hint.** The issue's traceback names `compiler.py … execute_sql`; the spec instead anchored on the issue *hint* ("copy the query"). An intent ledger that must map the *error string actually raised by the code* (`'ORDER BY term does not match any column in the result set.'`) back to the function that raises it would have put `get_order_by` in scope. Treat a public PR note that *"we've not hit the right strategy"* as evidence **against** the hinted fix.

3. **Don't let "out of scope" close an adjacent symptom-matching region.** PD-3 sat one function from the fix and matched the symptom (column/SELECT alignment for combined `values_list`) yet was discarded as unrelated. A guard: any latent finding whose *symptom* matches the issue's symptom string must be promoted to in-scope and spec'd, not deferred.

---

### Note for the primer (suggested correction)
`fvk-primer.md:148` cites `django-10554 SPEC.md:31-38` as a likely tell-#4 site ("root cause told as the thing fixed"). It should be **downgraded/corrected to a counter-example**: those lines narrate a *wrong* mechanism (`get_combinator_sql`/operand-sharing) that the gold patch does not implement, and quote only the *symptom* string. The real cause (`get_order_by` missing-case) is MISSING from the artifacts. Good illustration that a symptom-string match in `SPEC.md` is **not** sufficient for "present" — apply the pointed-at-the-spot test to the *cause*, not the symptom.
