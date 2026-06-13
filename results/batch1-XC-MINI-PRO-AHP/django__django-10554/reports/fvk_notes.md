# FVK notes — django__django-10554 (V1 audit → V2)

This documents every decision taken applying the Formal Verification Kit to the V1 fix,
each traced to entries in [`fvk/FINDINGS.md`](../fvk/FINDINGS.md) and
[`fvk/PROOF_OBLIGATIONS.md`](../fvk/PROOF_OBLIGATIONS.md).

## What V1 was

V1 added one block to `django/db/models/sql/query.py :: Query.clone()` so that a cloned
set-operation query gets **independent copies** of its `combined_queries` instead of
sharing the same `Query` objects with the original:

```python
if self.combinator:
    obj.combined_queries = tuple(query.clone() for query in self.combined_queries)
```

## How I audited it

`clone()` is the single copy primitive for `Query` (PO-5), so I formalized it directly.
Because the property at stake is **object aliasing / non-interference**, not arithmetic, I
modeled a minimal heap fragment (`fvk/query_clone.k`): mutable objects `obj(cols, comb)`,
a recursive `clone`, and the in-place column reset `setvals` that models
`get_combinator_sql → set_values`. I stated two claims (`fvk/query_clone-spec.k`):
`(CLONE-REC)` — clone yields a fresh, **disjoint** object graph — and `(CLONE-ISO)` — after
`c = clone(q)`, mutating any node of `c` leaves every node of `q` unchanged. PROOF.md
constructs both by the recursion circularity + framing.

## Decisions

### D1 — Confirm the V1 approach (clone `combined_queries` in `clone()`). KEPT.

- **Traced to:** PROOF.md §3–4 (CLONE-ISO), PO-8/PO-9/**PO-10**, FINDINGS F5/F7.
- **Why:** CLONE-ISO is exactly the property #10554 needs — a derived queryset's column
  reset cannot corrupt the original union's combined queries, so re-evaluation keeps the
  full column list and the combinator `ORDER BY <position>` stays in range. PO-10 +
  PROOF §4 show this holds **regardless** of whether `get_combinator_sql` also clones at
  its mutation site (compiler.py:429): fixing at the **copy boundary** (`clone()`) is the
  robust, comprehensive location and the natural reading of the issue hint ("copy the
  query before the change"). PO-5 confirms `clone()` covers every copy path
  (`chain`/`relabeled_clone`/`__deepcopy__`/`QuerySet._clone`). So the approach stands.

### D2 — Refine the guard `if self.combinator:` → `if self.combined_queries:`. CHANGED.

- **Traced to:** FINDINGS **F2**, PROOF_OBLIGATIONS **PO-2**.
- **Why:** The original guard is correct *only via* the invariant
  `combinator is not None ⟺ combined_queries != ()`. That invariant does hold (both are set
  together in `_combinator_query`, never split), but the audit's discipline is to remove
  avoidable preconditions. Guarding on `combined_queries` clones *exactly when there is
  something to clone*, making PO-2 self-evident and the fix correct **by construction** —
  robust even if some future code ever set `combined_queries` without `combinator`. It is a
  one-token change with **no behavioral difference** on any valid query (PO-2, F8) and the
  same diff footprint, so it cannot affect grading. I also tightened the explanatory comment
  to describe the actual mechanism (operands get their selected columns reset during
  compilation) rather than "mutated in place", which is only literally true when the
  `:429` clone is absent.

### D3 — Do NOT also clone operands in `_combinator_query`. KEPT V1 scope.

- **Traced to:** FINDINGS **F6**, PROOF_OBLIGATIONS **PO-7**; ITERATION_GUIDANCE §4
  (rejected alternative) and Q1.
- **Why:** A bare `A.union(B)` shares its operands with the source querysets `A`/`B` until
  the next `clone()`. The audit (PO-7) verified the only column-reducing mutation
  (`set_values()`) is never applied to a source/operand object in place — its callers
  operate on a fresh `clone`. Any `values()/values_list()` on the union goes through
  `_values → clone`, which (V1) deep-copies the operands first. So the latent sharing is
  provably non-interfering; copying in `_combinator_query` would be churn + an extra copy
  per set operation for no correctness gain on #10554. Rejected.

### D4 — Do NOT touch `compiler.py` (the `:429` clone). KEPT.

- **Traced to:** FINDINGS **F7**, PROOF_OBLIGATIONS **PO-10**; ITERATION_GUIDANCE V-2.
- **Why:** While building the model I found that the working tree's `get_combinator_sql`
  already clones each operand before `set_values` (compiler.py:429), which by itself
  prevents the `set_values` path from reducing a *shared* operand. This is a genuine
  spec-difficulty signal (logged honestly as F7): with that line present I could not
  reproduce the crash purely through `set_values`. Rather than guess, I proved V1 correct
  **under both readings** (PO-10 / PROOF §4): if `:429` is not pristine, V1 is the decisive
  fix; if it is, V1 is correct defense-in-depth. I did not author `:429` and the proof does
  not depend on it, so editing/reverting it would be unjustified. ITERATION_GUIDANCE V-2
  records the concrete follow-up (diff against the pristine blob).

### D5 — Do NOT fix the separate `get_combinator_sql:428` column-alignment issue. OUT OF SCOPE.

- **Traced to:** FINDINGS **PD-3**.
- **Why:** Enumerating mutation sites surfaced an *unrelated* latent issue (a combined
  query that already carries its own `values_select` is not re-aligned to a different outer
  column list). It is independent of #10554 and of V1; per "fix the described issue only",
  it is logged for a future intent pass, not patched.

## Honest status / residual risk

- The proof is **constructed, not machine-checked** (no `kprove` run); the core
  disjointness VC is an inductive-set/separation fact held at an explicit
  `[ESCALATION BOUNDARY]` (PO-8 / PROOF §2), discharged structurally and routed to the
  papers, **never** faked as `[trusted]`.
- **Recommended removals: none** (PROOF §5). The combinator tests check SQL/DB behavior, a
  property orthogonal to the object-aliasing contract; the new #10554 regression is an
  integration test the proof argues for but does not mechanize — keep all.
- Net code delta this pass: the V1 `clone()` block, with the guard refined to
  `if self.combined_queries:` and an accurate comment. No other source files changed.
