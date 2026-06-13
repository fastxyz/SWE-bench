# Control notes — audit of V1 for django__django-12325

## Outcome

After a systematic review (recorded in `review/FINDINGS.md`), **V1 stands
unchanged**. The review surfaced no correctness defect, no regression, and no
missing code path. The one-line change in `django/db/models/base.py` (guarding
the `parent_links` collection so an explicit `parent_link=True` field is never
shadowed by a plain `OneToOneField`) is correct, minimal, and complete.

No source files were edited in this control pass.

## Decision-by-decision justification

### Decision 1 — Keep the guarded `parent_links` assignment as the fix.
Traces to **F1** and **F2**. The guard makes both field orderings in the issue
select `document_ptr` (F1), which is the single root cause behind both reported
symptoms — the `ImproperlyConfigured` error and the runtime
"`document_ptr_id` not populated" failure (F2). Because `parent_links` feeds the
concrete branch at `base.py:251` and from there `_meta.parents`, fixing the
selection here fixes the entire chain. Nothing downstream needed a separate
change (F10).

### Decision 2 — Do NOT narrow the loop to only `parent_link=True` fields.
Traces to **F3**. The simplest-looking fix (skip non-parent-link OneToOnes
entirely) would break the documented/tested contract that a lone non-parent-link
`OneToOneField` to the parent must still raise `Add parent_link=True to …`.
V1 deliberately keeps all OneToOnes in `parent_links` and only reorders
precedence, so `test_missing_parent_link` and the equivalent "simpler case" from
the ticket continue to raise — which is the intended behavior, not a bug.

### Decision 3 — Keep the guard form (`continue` on "parent link being shadowed")
rather than switching to the ticket's `sorted(...) + not in` PR.
Traces to **F13** and **F8**. The two are equivalent for the reported bug and
all realistic cases; V1's explicit guard states the intent more directly and
avoids the (harmless-but-real) cross-base precedence flip that the
`reversed()` + `not in` combination introduces. Switching would be churn with no
behavioral benefit.

### Decision 4 — Leave abstract-inheritance handling untouched.
Traces to **F4** and **F8**. Abstract-inherited parent links are resolved by the
separate `base_parents` copy/update path (`base.py:281-299`), which never
consults `parent_links`. `test_abstract_parent_link` therefore remains green,
and the only cases where V1's `parent_links` value differs from the original are
overwritten by that abstract path (final `_meta.parents` identical). No edit is
needed or appropriate there.

### Decision 5 — Do not add a check for duplicate parent links.
Traces to **F7**. Two `parent_link=True` fields to the same parent is an invalid
configuration that the original code already resolved silently (last wins), and
no system check exists for it. V1 preserves that behavior exactly, so adding new
validation would be scope creep unrelated to the reported issue.

### Decision 6 — Do not implement the speculative enhancements from the thread.
Traces to **F12**. "pk OneToOne implies parent link" and "key `parent_links` by
`related_name`" are larger, debated design changes; the first would conflict
with the contract protected in F3, and the second is unnecessary (one parent
link per parent). The task is a minimal, targeted bug fix, so these are
intentionally excluded.

### Decision 7 — No new imports, no style changes beyond the local guard.
Traces to **F9** and **F11**. The accessed attributes are always present on a
`OneToOneField`, so the guard is null-safe; the needed helpers were already
imported; and the local style matches the surrounding code. There is nothing to
add or reformat.

## Re-verification performed (no execution available)

- Re-read `benchmark/PROBLEM.md`; both code snippets and both reported symptoms
  map to the single `parent_links` selection defect (F1, F2).
- Re-read the consumers of `parent_links`/`_meta.parents`: the concrete vs.
  abstract branches of the mro loop (`base.py:248-299`), `Options._prepare`
  (`options.py:241-257`), and `Options.get_ancestor_link`
  (`options.py:613-631`). Confirmed `parent_links` only influences the concrete
  branch, which is exactly the issue's scenario (F1, F4, F10).
- Confirmed `local_fields` is creation-counter ordered via
  `bisect.insort` (`options.py:266-277`), validating the "declaration order"
  reasoning used throughout the review.
- Confirmed no duplicate-parent-link system check exists in
  `django/core/checks` (F7).
- Hand-traced V1 against: the two issue orderings (F1), `test_missing_parent_link`
  (F3), `test_abstract_parent_link` (F4), `ParkingLot` (F5), multi-parent MTI
  (F6), duplicate parent links (F7), and contrived abstract+concrete
  double-inheritance (F8). All produce correct or unchanged results.
