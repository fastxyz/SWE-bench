# PROOF OBLIGATIONS — django__django-10554, V1 fix

Each obligation needed to conclude **CLONE-ISO** (after `c = clone(q)`, an in-place
column reset on any object reachable from `c` leaves every object reachable from `q`
unchanged). Status: ✅ discharged · ◑ discharged structurally, residual at escalation
boundary · ✅(code) discharged by inspection of the Django source.

| # | Obligation | How discharged | Status |
|---|---|---|---|
| PO-1 | **Fresh allocation.** `clone()` returns a brand-new object for the root and for every combined query. | `clone()` begins `obj = Empty()` (a new instance); the recursive `query.clone()` does the same for each operand. Modeled by `allocClone` drawing `N` from `<next>` with `requires notBool (N in_keys(OBJS))`. | ✅(code) |
| PO-2 | **Guard fires iff there is something to clone.** | V1 guard is now `if self.combined_queries:`. Trivially: clones exactly the non-empty operand tuples. (Previously relied on `combinator is not None ⟺ combined_queries != ()`; that invariant *also* holds — both set only together in `_combinator_query`, never split — but the refined guard no longer needs it.) | ✅ |
| PO-3 | **Termination / acyclicity (SC-1).** The recursive `clone` over `combined_queries` halts. | `_combinator_query` builds `combined_queries` from *already-constructed* querysets; a query cannot transitively appear inside an operand created before it ⇒ finite DAG, in fact a tree of distinct objects ⇒ no back-edge ⇒ the `cloneList` recursion is well-founded on graph size. | ✅(code) |
| PO-4 | **Clone depth ≥ mutation depth (SC-3).** Every state `set_values()` writes is private to a clone. | `set_values()` ⇒ `clear_deferred_loading` (rebind), `clear_select_fields` (rebind `select`,`values_select`), `set_extra_mask`/`set_annotation_mask` (write masks — **deep-copied** by `clone`), `values_select = …` (rebind), `add_fields → get_initial_alias` (write `alias_map` — **deep-copied** by `clone`) `→ set_select` (rebind `select`,`default_cols`). No in-place mutation of a tuple/list shared with the original. | ✅(code) |
| PO-5 | **Every copy path goes through `clone()`.** | `chain()→clone()`; `relabeled_clone()→clone()`; `__deepcopy__()→clone()`; `QuerySet._clone()→query.chain()→clone()`. Grepped: no other `Query` copy constructor. | ✅(code) |
| PO-6 | **No reliance on operand identity.** Deep-copying operands changes no observable result. | `get_combinator_sql` only *iterates* `combined_queries` and compiles each; no `is`/identity check; `tests/queries` never references `combined_queries`. Structural copies emit identical SQL. | ✅(code) |
| PO-7 | **Sources are never mutated in place (justifies F6).** | The only column-reducing mutation `set_values()` has exactly two callers — `QuerySet._values()` (on a fresh `clone`) and `get_combinator_sql()` (on `compiler.query.clone()`); neither writes a source/operand object directly. | ✅(code) |
| PO-8 | **Disjointness (the CLONE-REC core).** `reach(OBJS', clone(R)) ∩ reach(OBJS, R) = ∅`. | Proved by the recursion **circularity** over the combined-query tree (PROOF.md §3): base case = no operands (singleton fresh root); step = fresh root + per-operand `clone`, each disjoint by the coinductive hypothesis, all freshly allocated (`≥ N0`). The set-level `∩ = ∅` over the inductive `reach` predicate is the **escalation boundary**. | ◑ |
| PO-9 | **Non-interference (CLONE-ISO) from PO-8.** In-place `setvals(M,V)` with `M ∈ reach(c)` preserves `colsOf` of every `id ∈ reach(q)`. | `setvals` rewrites only `OBJS[M]`; by PO-8 `M ∉ reach(q)`, so by framing every `id ∈ reach(q)` keeps its `obj(cols,·)`. Discharged structurally given PO-8. | ◑ |

## Independence from `compiler.py:429`

A distinguishing obligation, because the audited tree contains a clone at the mutation
site (compiler.py:429); see FINDINGS F7:

- **PO-10. V1 is sufficient on its own.** Even if `get_combinator_sql` did **not** clone
  before `set_values` (i.e. it mutated `compiler.query` in place), CLONE-ISO still makes the
  original safe: a queryset *derived* from a union owns operands disjoint from the original's
  (PO-8 applied at the derivation's `clone()`), so the in-place reset hits only the
  derivative's private operands. *Discharged by PROOF.md §4* (the non-interference holds for
  either definition of `get_combinator_sql`). This is why V1 is the **robust** location for
  the fix (the copy boundary) rather than the conditional clone at the mutation site.

## Verification conditions and their tier

- **VC-fresh** (`N ∉ keys(OBJS)`, `N ≥ N0`): linear over the allocator → Z3 tier. ✅
- **VC-frame** (an `OBJS[M <- …]` update leaves `OBJS[id]` for `id ≠ M`): map
  non-aliasing, needs `M =/=Int id`, supplied by PO-8. ✅ given PO-8.
- **VC-disjoint** (`reach(clone(R)) ∩ reach(R) = ∅`): quantifies over an inductive set →
  **`[ESCALATION BOUNDARY]`**, routed to separation logic + matching-μ-logic
  (`knowledge/sources.md`). Discharged *structurally* (per-node freshness) but the
  set-equality is not closed by the bundled `[simplification]` tier. ◑ — **not** admitted
  as `[trusted]`.
