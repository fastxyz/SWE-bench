# Control notes — review outcome for django__django-10554

This documents every decision taken during the audit of the V1 fix, each traced to a
numbered entry in `review/FINDINGS.md`. Net result: **V1 stands**, with a single
comment clarification. No behavioural code change was needed.

## What changed between V1 and the controlled version

- **Only** the explanatory comment in `Query.clone()` was reworded for accuracy.
- The fix logic is unchanged:
  ```python
  if self.combinator:
      obj.combined_queries = tuple(query.clone() for query in self.combined_queries)
  ```

## Decisions

### D1 — Keep the core fix (clone `combined_queries` in `Query.clone()`)
Traces to **F1, F2, F3, F6, F7, F8, F11**.

The review re-derived the root cause (F1): `combined_queries` is shared by reference
across a combinator query and all its clones because `clone()` shallow-copies
`__dict__`, and the compiler mutates those branch queries (`set_values()` to align
columns) while emitting a positional `ORDER BY`. Cloning the branches per clone is the
precise, root-level remedy and matches the issue's hint about copying the query.

Crucially (F2), I verified the fix is **self-sufficient**: tracing evaluation of the
reproduction both with and without the existing `get_combinator_sql` clone
(compiler.py:429) shows the original union's branches stay at their full column list on
re-evaluation in either case, so the `ORDER BY position N` crash cannot occur. The
review found no regressions: nothing relies on branch identity (F6); annotated /
`Exists(OuterRef())` branches are unaffected because `clone()` shares expression
objects exactly as it already does everywhere (F7); `count()`/`get_aggregation()` and
`__deepcopy__()` keep (or improve) their behaviour (F8); and no new error paths are
introduced (F11). Nested set operations are handled by the natural recursion of
`clone()` (F3). Because the fix is correct, self-sufficient, and regression-free, it is
kept as the solution.

### D2 — Reword the comment only
Traces to **F9**.

The original comment claimed the shared branches "are mutated in place … by
set_values()". Since `get_combinator_sql` clones a branch before calling
`set_values()`, that wording over-claimed a mutation that is guarded at that call site.
The comment now states the general, accurate rationale — branch queries are mutable
state aligned via `set_values()` during compilation and therefore must not be shared
between a query and its clones — without asserting the shared objects are definitely
mutated. This is the one edit made in this pass; it changes no behaviour.

### D3 — Keep the `if self.combinator:` guard (no change)
Traces to **F4**.

`combinator` and `combined_queries` are always set together; the guard is True exactly
for set-operation queries and cheaply skips everything else. An alternative
`if self.combined_queries:` would be equivalent and only marginally more defensive
against an impossible state, so the clearer, conventional `if self.combinator:` was
retained. No correctness difference, so no change.

### D4 — Accept the per-clone copy cost (no change)
Traces to **F5**.

Cloning each branch on every `clone()` is O(branches) extra work, mirroring how
`clone()` already deep-copies other shared mutable state. There is no cheaper way to
guarantee isolation and it is not a correctness issue, so the trade-off is accepted
without code change.

### D5 — Leave `get_combinator_sql` (compiler.py:429) untouched (no change)
Traces to **F2**.

The pre-existing `compiler.query = compiler.query.clone()` before `set_values()` is a
narrower guard at one mutation site; it is independently correct and harmless next to
the root-level isolation (at worst a redundant double-copy). Removing it would be a
risky, unrelated edit and could re-expose a mutation if any future code path bypassed
`clone()`. The review's guidance to keep changes minimal and targeted means it is left
exactly as found.

### D6 — Do not fix the unrelated branch-values mismatch (no change)
Traces to **F10**.

`get_combinator_sql`'s `if not compiler.query.values_select and
self.query.values_select` does not re-align a branch that already carries a different
`values_select`. This is a separate issue from #10554 (whose reproduction uses
unvalued branches) and outside the minimal-change scope, so it is documented in the
findings and deliberately left alone.

## Conclusion

The audit confirmed V1 is the correct, robust, regression-free fix for the reported
crash (D1, grounded in F1/F2/F6/F7/F8/F11). The only modification made in this pass is
a comment clarification for accuracy (D2/F9). All other review observations
(F3/F4/F5/F10 and the existing compiler guard) were evaluated and intentionally left
without code changes for the reasons traced above.
