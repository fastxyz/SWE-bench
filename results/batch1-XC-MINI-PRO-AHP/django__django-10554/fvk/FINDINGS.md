# FINDINGS — django__django-10554, V1 fix audit

Plain-language findings from formalizing `Query.clone()`'s isolation contract.
Format: `input/scenario → observed vs expected`. Non-blocking; this is advice +
the audit trail behind the V1 confirm/refine decision.

Legend: ✅ confirms V1 is sound on this point · ✏️ drove a refinement · ⚠️ open /
spec-difficulty signal (FVK "benefit 2").

---

## F1 ✅ — Deep-copy depth is *exactly* sufficient (no more, no less)

- **Scenario:** clone a union query, then `set_values()` runs on a combined query
  during compilation.
- **Observed (V1):** `clone()` deep-copies `alias_map`, `where`, `annotations`, and the
  `*_select_mask`s, and rebinds the scalar/tuple fields; the V1 line additionally clones
  the `combined_queries`. `set_values()` only ever **rebinds** `select` / `values_select`
  / `default_cols` / `deferred_loading` (new tuples/objects) or mutates `alias_map` and
  the masks — all of which a cloned `Query` already owns privately.
- **Expected:** a clone must be deep enough that the compilation-time mutation cannot
  reach the original.
- **Verdict:** ✅ The `Query`-object granularity is enough; the immutable column *tuples*
  need not be copied. Cloning the combined *queries* (V1) closes the last shared mutable
  node. See PO-4.

## F2 ✏️ — Guard correctness: `combinator` vs `combined_queries`

- **Scenario:** which queries get their combined operands cloned.
- **Observed (V1 as written):** the guard was `if self.combinator:`. That is correct
  **only because** of the invariant `combinator is not None ⟺ combined_queries != ()`
  (both are set together in `_combinator_query` and never split — verified, PO-2).
- **Refinement applied:** changed the guard to `if self.combined_queries:`. It clones
  exactly when there is something to clone, **removing the dependency on that invariant**
  (a discharged-then-eliminated proof obligation) and being robust if any future code
  ever set `combined_queries` without `combinator`.
- **Verdict:** ✏️ one-token change, no behavioral difference on any valid query; makes the
  fix correct *by construction*.

## F3 ✅ — Aliased operand (`qs.union(qs)`)

- **Input:** `qs.union(qs)` ⇒ `combined_queries = (qs.query, qs.query)` — the **same**
  object twice.
- **Observed (V1):** `tuple(query.clone() for query in ...)` clones each *element*, so the
  result is **two distinct clones**. No code relies on the two entries being identical
  (`get_combinator_sql` compiles each independently; no test references identity — PO-6).
- **Expected:** independent branches.
- **Verdict:** ✅ Strictly better than the shared-twice base; correct.

## F4 ✅ — Nested set operations terminate

- **Input:** `A.difference(B.intersection(C))` — a combined query that is itself a
  combinator.
- **Observed (V1):** the recursive `query.clone()` re-enters the guard and clones the
  inner operands too. The recursion terminates because `combined_queries` are built from
  *pre-existing* querysets, giving a finite acyclic graph (no query transitively contains
  itself). See SC-1 / PO-3.
- **Verdict:** ✅ Correct and terminating for arbitrary nesting depth.

## F5 ✅ — All copy paths are covered

- **Scenario:** is there a way to copy a query that bypasses `clone()`?
- **Observed:** `chain()`, `relabeled_clone()`, `__deepcopy__()`, and `QuerySet._clone()`
  all call `Query.clone()` (PO-5). The only non-`clone` assignment of `combined_queries`
  is `_combinator_query` building the union from the source queries (F6).
- **Verdict:** ✅ Fixing `clone()` isolates every clone-derived queryset.

## F6 ✅ (latent, harmless) — A *bare* union shares operands with its sources

- **Scenario:** `u = A.union(B)` → `u.query.combined_queries = (A.query, B.query)` — the
  **source** query objects, not copies (set directly in `_combinator_query`, before any
  `clone()`).
- **Observed:** V1 isolates on the *next* `clone()`, not at creation. So a bare `u` shares
  its operands with `A`/`B`.
- **Why it is still safe (PO-7):** `set_values()` — the only column-reducing mutation — is
  *never* applied to a source query object directly. Its two callers are
  `QuerySet._values()` (operates on a fresh `clone`) and `get_combinator_sql()` (operates
  on `compiler.query.clone()`); and any `values()/values_list()` on `u` itself goes
  through `_values → clone`, which (V1) deep-copies the operands first. A bare `u`
  evaluated *without* a column list never calls `set_values()` at all.
- **Verdict:** ✅ Latent sharing, provably non-interfering on the current code. A stricter
  variant (clone the operands in `_combinator_query` too) was **considered and rejected**
  as unnecessary churn — see ITERATION_GUIDANCE "rejected alternatives".

## F7 ⚠️ — Spec-difficulty signal: the base ALSO clones at the mutation site

- **Observation while building the model:** the audited tree's
  `get_combinator_sql` (compiler.py:**429**) already does
  `compiler.query = compiler.query.clone()` **before** `set_values()`. In isolation, that
  clone-at-the-mutation-site *already* prevents `set_values()` from reducing a *shared*
  combined query: the original operand keeps its full column list.
- **Consequence (honest):** With that line present, I could **not** construct a concrete
  input that reproduces the reported crash purely through the `set_values` path — the
  combined operands are never mutated in place. That difficulty is itself a finding (FVK
  "if it's hard to reproduce/spec, say so"). Two readings, both leaving V1 *correct*:
  1. **`compiler.py:429` is not in the pristine base** (file-mtime evidence during V1
     suggested `compiler.py` had been touched after checkout). Then the true base reduces
     the *shared* operands in place, and **V1 is the decisive fix**: with `clone()`
     deep-copying `combined_queries`, a derived queryset owns *its own* operand objects,
     so `set_values()` (even without the `:429` clone) cannot reach the original.
     *Traced:* PROOF.md §4 proves exactly this — V1 yields non-interference **regardless**
     of whether `get_combinator_sql` clones before `set_values`.
  2. **`compiler.py:429` is genuine.** Then V1 is **defense-in-depth at the copy
     boundary** — the canonical reading of the issue hint ("copy the query"). It is still
     correct and closes the sharing comprehensively (the `:429` clone is conditional —
     only the `not compiler.query.values_select and self.query.values_select` branch —
     whereas `clone()` isolation is unconditional).
- **The user's own diagnostic supports the copy-boundary fix.** The reporter notes that
  *iterating* `qs` directly works (`[d.id for d in qs]` compiles `qs.query`) but
  *re-displaying* it breaks (`repr` slices → compiles a **clone** of `qs.query`). The
  bug manifests on the **clone path** — precisely where V1 acts.
- **Verdict:** ⚠️ V1 is correct under both readings; what is *uncertain* is whether V1 is
  strictly necessary or also-sufficient given `:429`. I did **not** modify `compiler.py`
  (I did not create that line; reverting it would be guesswork — see ITERATION_GUIDANCE).

## F8 ✅ — No false test breakage from deeper copying

- **Scenario:** does deep-copying operands on every `clone()` change any observable result
  besides isolation?
- **Observed:** combined queries produce identical SQL whether they are the shared objects
  or fresh structural copies (same model, same filters); no test or code depends on operand
  object identity (PO-6). The only cost is extra allocation on each clone of a set-operation
  query.
- **Verdict:** ✅ Behavior-preserving for all correct cases; pure isolation gain.

---

## Proof-derived findings (from constructing PROOF.md)

- **PD-1 (capability / ESCALATION BOUNDARY).** CLONE-REC's core obligation —
  `reach(clone(R)) ∩ reach(R) = ∅` — is a **heap-separation / fresh-allocation** fact over
  an inductively-defined `reach` set. The bundled VC tier (linear arithmetic + map
  extensionality) does not discharge inductive-set / separation VCs. The **structure**
  (recursive `clone`, the circularity on its contract, the per-node freshness step) is
  discharged in PROOF.md §3; the residual `∩ = ∅` over `reach` is marked
  `[ESCALATION BOUNDARY]` and routed to separation-logic + matching-μ-logic, **not**
  faked as `[trusted]`. *Classification:* proof-capability gap, **not** a code bug.
- **PD-2 (needed side condition = real precondition).** The proof is *forced* to assume
  **SC-1 acyclicity** of the combined-query graph. That is a genuine precondition the code
  relies on implicitly; it holds because operands pre-exist their parent. If a future
  change ever let a set operation reference itself, `clone()` would not terminate. *Action:*
  keep it stated (SPEC SC-1) and consider an explicit invariant/assert if that ever
  becomes reachable.
- **PD-3 (unrelated latent bug, out of scope).** While enumerating mutation sites,
  `get_combinator_sql`'s `if not compiler.query.values_select and self.query.values_select`
  guard (compiler.py:428) means a combined query that **already** carries its own
  `values_select` is *not* re-aligned to a *different* outer column list — a column-count
  mismatch for `union()` of pre-`values_list()` querysets re-projected to other columns.
  This is **separate** from #10554 and from V1; left untouched per "fix the described issue
  only". Logged for a future intent pass.
