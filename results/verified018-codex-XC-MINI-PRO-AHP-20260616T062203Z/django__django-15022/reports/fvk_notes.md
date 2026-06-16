# FVK Notes

## Decisions

1. Kept V1's core approach: collect per-token OR clauses and apply them after
   the token loop.

   Trace: `fvk/FINDINGS.md` F-001 identifies the legacy per-token
   `queryset.filter()` loop as the issue root cause. `fvk/PROOF_OBLIGATIONS.md`
   O3 requires the documented AND-of-ORs predicate, O4 requires one search
   filter operation, and O5 requires all term clauses to reach the ORM through
   one `Query.add_q()` path.

2. Refined V1 from `queryset.filter(models.Q(*term_queries))` to
   `queryset.filter(*term_queries)`.

   Trace: `fvk/FINDINGS.md` F-002 notes that V1 was semantically correct but
   added an unnecessary nested AND wrapper because `QuerySet.filter()` already
   wraps positional arguments in a `Q`. O4 and O5 only require one filter call
   carrying all term clauses, which `filter(*term_queries)` satisfies more
   directly.

3. Preserved lookup construction and duplicate detection unchanged.

   Trace: O2 requires existing `construct_search()` behavior for prefixes,
   explicit lookups, `pk`, and default `icontains`. O6 requires the
   `lookup_spawns_duplicates()`-based duplicate flag to remain intact. No FVK
   finding justified changing those paths.

4. Rejected preserving the old chained-filter semantics for multi-valued
   relations.

   Trace: F-003 records the ambiguity: chained filters can allow different
   related rows to satisfy different terms. O3 follows the documented single
   SQL `WHERE` predicate shape, while O4/O5 follow the issue's explicit demand
   to remove the per-word `qs.filter(...)` pattern. There is no public evidence
   requiring the legacy different-row behavior.

5. Did not run tests, Python, or K tooling.

   Trace: F-004 records the workspace restriction and the FVK honesty gate. The
   exact future `kompile`, `kast`, and `kprove` commands are written in
   `fvk/PROOF.md` and `fvk/ITERATION_GUIDANCE.md` instead of being executed.

## Result

The final source change remains minimal and source-only:

- `repo/django/contrib/admin/options.py` now accumulates `term_queries` and
  calls `queryset.filter(*term_queries)` once for nonempty search terms.

The FVK audit concludes that V2 satisfies the stated spec and proof obligations
at the constructed-proof level, with residual risk limited to the documented
absence of machine checking and runtime SQL inspection in this workspace.
