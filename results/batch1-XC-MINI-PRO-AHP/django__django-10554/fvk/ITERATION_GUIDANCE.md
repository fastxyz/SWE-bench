# ITERATION GUIDANCE — django__django-10554

Next-iteration feedback distilled from `/formalize` + `/verify`. The default FVK
posture is *gather evidence, don't silently re-patch*; the one code change made this pass
(F2 guard refinement) is small, behavior-preserving, and traced below.

## 1. Decision this pass

**Confirm V1 + one refinement.** The audit confirms the V1 approach (deep-copy
`combined_queries` in `Query.clone()`) establishes the correct **isolation /
non-interference** contract (CLONE-ISO) that #10554 needs, and that the contract holds
*regardless* of whether `get_combinator_sql` clones at its mutation site (PROOF.md §4,
PO-10). The single refinement:

- **Guard `if self.combinator:` → `if self.combined_queries:`** (FINDINGS F2 / PO-2):
  clone exactly when there are operands to clone, removing the dependency on the
  `combinator ⟺ combined_queries` invariant. One token; no behavioral change on any valid
  query.

Nothing else in `repo/` was changed.

## 2. Open items / recommended verifications

- **V-1 (run the machine check).** Execute PROOF.md §6 (`kompile`/`kprove`). Expected:
  linear/framing VCs → `#Top`; the inductive `reach`-disjointness VC stays open at the
  escalation boundary. Only after `#Top` would any test-removal be safe — and this proof
  recommends **no** removals anyway (PROOF.md §5).
- **V-2 (settle F7 — is `compiler.py:429` pristine?).** The clone at the `set_values`
  mutation site exists in the working tree; file-mtime hints during V1 suggested
  `compiler.py` may have been touched post-checkout. **Recommended:** diff the working
  `compiler.py` against the pristine `14d026cccb…` blob. *If* `:429`'s
  `compiler.query = compiler.query.clone()` is absent upstream, V1 is the decisive fix and
  everything is consistent. *If* it is present, V1 is defense-in-depth and equally correct.
  I deliberately did **not** edit `compiler.py`: I did not author that line, and the proof
  shows V1 is correct either way (PO-10), so reverting it would be unjustified guesswork.
- **V-3 (acyclicity invariant, PD-2/SC-1).** `clone`'s termination relies on the
  combined-query graph being acyclic. It is, today (operands pre-exist their parent). If a
  future feature ever lets a set operation reference itself, add an explicit guard/assert;
  until then it stays a documented precondition (SPEC SC-1).

## 3. UltimatePowers questions (for the intent layer)

- **Q1.** Should a *bare* `A.union(B)` be isolated from its source querysets `A`/`B` at
  *creation* time, or only once it is cloned for a further operation? (Today: only on
  clone; proven harmless because sources are never mutated in place — F6/PO-7. Answer
  drives whether `_combinator_query` should also copy its operands.)
- **Q2.** For `union()` of querysets that already carry their own `values_list()`, if the
  union is then re-projected to a *different* column list, should the operands be
  re-aligned to the new outer columns or kept? (The current `get_combinator_sql:428`
  guard keeps them — the separate latent issue PD-3. Out of scope for #10554.)
- **Q3.** Is deep-cloning combined queries on *every* `clone()` an acceptable cost, or is a
  copy-on-write / lazier scheme wanted for very deep set-operation trees? (Correctness is
  fine either way; this is a performance-intent question.)

## 4. Recommended next code/spec changes — and rejected alternatives

- **Adopted:** F2 guard refinement (done).
- **Rejected — clone operands inside `_combinator_query` too.** Would close the F6 bare-union
  sharing at creation, but PO-7 shows that sharing is non-interfering on the current code
  (sources are never `set_values()`'d in place). It adds churn + an extra copy on every set
  operation for no correctness gain on #10554. Revisit only if Q1 says "isolate at
  creation".
- **Rejected — touch `compiler.py:429`.** See V-2: not authored here, and PO-10 proves V1 is
  correct independent of it.
- **Rejected — narrow the fix to `union()` only.** Intersection/difference share the same
  `combined_queries` machinery and the same hazard; `clone()` covers all three uniformly,
  which is why fixing at the copy boundary (not per-combinator) is the right granularity.

## 5. Tests

- **Add (kept until V-1/V-2):** the #10554 regression — build `A.union(B).order_by(<col>)`,
  evaluate it, derive+evaluate `qs.order_by().values_list(<pk>)`, then **re-evaluate** the
  original and assert it still returns the full rows (and, for the relabel, that the
  combinator `ORDER BY` is still in range). This is an integration test the constructed
  proof argues for but does not machine-check; keep it.
- **Keep:** all existing `tests/queries/test_qs_combinators.py` (SQL/DB behavior — not
  subsumed by an object-aliasing proof; PROOF.md §5).
- **Remove:** none.
