# FINDINGS.md — django__django-15957

Plain-language findings from formalizing the V1 fix, each as
`input → observed vs expected`. **Non-blocking.** A clean spec *was* writable for the
core (the off-by-one closed form `max(0, min(m,high) − low)`), which is itself a positive
signal: the central arithmetic is not a code smell. Findings below are corner cases,
intentional limitations, and the one judgement-call (the guard relaxation) — **none is a
correctness bug in the supported domain.**

---

## Headline: no correctness bug found in the supported domain

The off-by-one — the only place a top-N-per-group rewrite usually hides a bug — is
**proven correct** (PO1/PO2/PO3). V1's bounds `RowNumber() > low` and
`RowNumber() <= high` select exactly Python's `rows[low:high]`. Spot-checks of the m2m
QUALIFY interaction (PO5) and the guard containment (PO7) also came back clean.

---

## Finding 1 — `to_attr` and no-`to_attr` both supported (positive / scope)
- input: `Prefetch('post_set', Post.objects.all()[:3], to_attr='ex')` → observed: each
  `category.ex` is the 3 example posts. ✓
- input: `Prefetch('post_set', Post.objects.all()[:3])` (no `to_attr`) → observed:
  `category.post_set.all()` is the 3 posts. ✓ This second form only works because of the
  `_filter_or_exclude` guard relaxation (F3 / PO6 / PO7). Expected per the general issue
  intent ("Prefetch objects don't work with slices"): both work. **Confirmed.**

## Finding 2 — no-`to_attr` cached queryset is itself sliced (documented limitation)
- input: after the no-`to_attr` prefetch above, `category.post_set.filter(published=True)`
  → observed: raises `TypeError("Cannot filter a query once a slice has been taken.")`.
- expected: this is consistent — you sliced the relation, so the cached queryset carries
  the slice and cannot be further filtered, exactly like any sliced queryset. `.all()`,
  iteration, `len()`, and `count()` (all `_result_cache`-served) work fine.
- **Not a bug.** It is the natural consequence of caching a sliced relation; the
  `to_attr` form (a plain list) sidesteps it. Recommend a one-line docs note.

## Finding 3 — unordered slice ⇒ non-deterministic per-partition rows (corner case)
- input: `Prefetch('post_set', Post.objects.all()[:3])` where neither the queryset nor
  `Post.Meta` defines an ordering → observed: the window has no `ORDER BY`, so *which* 3
  rows per category is database-defined / non-deterministic.
- expected: identical to the guarantee an unordered `Post.objects.all()[:3]` already
  gives. `mini-orm-spec.k` proves the *count* and *position-set* regardless of order; it
  does not (and cannot) pin *which* rows when the order is unspecified.
- **Not a bug** — behaviour matches plain unordered slicing. Recommend documenting "use an
  explicit `order_by()` for deterministic example rows."

## Finding 4 — redundant `RowNumber() > low` when `low == 0` (provably harmless)
- input: `qs[:3]` → low=0. V1 emits `GreaterThan(win, 0)` (always true,
  `RowNumber() ≥ 1`) **and** `LessThanOrEqual(win, 3)`.
- observed vs expected: the kept set is unchanged (`PO0`: `k>0` removes nothing). The only
  effect is a second, redundant window reference in the SQL; the QUALIFY rewrite dedupes
  equal window expressions to one annotation, so even the SQL cost is ~nil.
- **Not a bug.** Deliberately kept unconditional to match the established upstream pattern
  and to keep the predicate construction branch-free; the proof shows the size delta is 0.
  (Micro-optimization `if low_mark: predicate &= GreaterThan(...)` is possible but
  behaviour-identical and was *rejected* — divergence without correctness gain.)

## Finding 5 — backend without window functions raises (intended, explicit)
- input: a sliced prefetch on a backend with `supports_over_clause == False` → observed:
  `NotSupportedError("Prefetching from a limited queryset is only supported on backends
  that support window functions.")`.
- expected: a clear, early error beats silently loading every row (which is the very thing
  the ticket wants to avoid). **Confirmed intended.** Keep backend-specific tests for this.

## Finding 6 — single-valued relations still raise on sliced prefetch (intentional / PO8)
- input: `Prefetch('author', Author.objects.all()[:1])` (forward FK) → observed: raises
  the slice `TypeError`.
- expected: slicing a ≤1-per-parent relation is not meaningful (a single global LIMIT
  across all parents would be wrong, and a per-parent top-1 is just the relation itself).
  Left unchanged on purpose. **Not a bug**; documented limitation.

## Finding 7 — GenericRelation prefetch not covered (intentional / PO9)
- input: a sliced prefetch through a `GenericRelation` → observed: raises.
- expected: out of scope for this ticket; correct support needs a composite
  `(content_type, object_id)` partition. **Not a bug**; tracked for a follow-up.

---

## Spec-difficulty signal: LOW
A clean precondition (`0 ≤ low ≤ high`, **enforced** by `Query.set_limits` — itself a
positive finding, like `sum`'s `n ≥ 0` guard) and a clean closed form both exist. The only
"awkwardness" is F3's guard exception (`and not self._defer_next_filter`), and that
awkwardness is fully explained by an existing design seam (`_apply_rel_filters` deferring
filters for caches), not by a hidden bug — see PO6/PO7. No finding rises to "fix the code."

## Proof-derived findings from `/verify`
See `PROOF.md` §5 and `ITERATION_GUIDANCE.md`. Summary: every proof obligation either
discharged (PO0–PO3, PO6, PO7) or routed to the trusted base with a spot-check (PO4, PO5);
no obligation forced an admitted/`[trusted]` *correctness* claim about V1's own logic.
