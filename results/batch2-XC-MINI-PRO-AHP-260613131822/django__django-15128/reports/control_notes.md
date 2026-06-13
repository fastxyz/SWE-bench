# Control notes — V2 review outcome for django__django-15128

This documents the review of the V1 fix (see `review/FINDINGS.md`) and every
resulting decision. The V1 approach is **confirmed correct**; two small,
behaviourally transparent improvements were applied. No behavioural/bug-fixing
logic changed.

## Summary of the V1 fix (unchanged in substance)
`Query.combine` now bumps the rhs query's `alias_prefix` to a distinct letter —
operating on a clone, keeping the shared base-table alias — before building the
`change_map`, so the map's keys (rhs aliases) and values (lhs-prefixed aliases /
table names) are always disjoint and `change_aliases`' invariant holds wherever
the map flows (including into queryset subqueries in the `where` clause).
`bump_prefix` gained an `exclude` parameter to support this, and the
`change_aliases` disjointness assertion was documented.

## Changes made in V2

### C1 — Skip the rhs clone when rhs contributes no joins
**Trace: F9 (with F1/F3 establishing it is safe).**
Changed the guard from `if self.alias_prefix == rhs.alias_prefix:` to
`if self.alias_prefix == rhs.alias_prefix and len(rhs.alias_map) > 1:` and
updated the explanatory comment. V1 cloned rhs on essentially every `|`/`&`
(both operands default to prefix `'T'`), including the very common base-only
case where there is nothing to relabel and no intersection is possible
(`rhs_tables` is empty when `len(rhs.alias_map) <= 1`). Per F9 the guard only
gates an internal clone — it changes neither `self.alias_prefix`, the generated
SQL, nor rhs — so it removes wasted work with no test risk. F1/F3 confirm the
fix's correctness and output-equivalence are unaffected because the skipped case
produced an empty effective relabelling anyway.

### C2 — Clarify the `bump_prefix` `exclude` docstring
**Trace: F11.**
Replaced the ambiguous "To prevent changing aliases use the exclude parameter"
with "Aliases in the optional exclude set are not relabelled," which states
precisely what `exclude` does and matches the implementation (F10).

## Decisions to keep V1 as-is (with justification)

### K1 — Keep the bump-the-rhs-prefix approach (not relaxing the assertion)
**Trace: F1, F13, F15.**
F1 confirms the approach fixes the documented root cause; F15 explains why
relaxing/removing the `change_aliases` assertion was rejected (the assertion is
a real invariant, and the maintainer guidance is to prevent the intersecting
map at its source). F13 confirms the assertion (now documented) is upheld.

### K2 — Keep cloning rhs (do not bump in place)
**Trace: F4, F5.**
`combine` documents that rhs is not modified. F4 enumerates every structure
`change_aliases` touches and shows that cloning preserves the contract, provided
`table_map`'s shared list values are also copied. Bumping in place would corrupt
the caller's queryset; cloning is the safe choice regardless of whether any test
checks rhs immutability.

### K3 — Keep the explicit `table_map` list copy
**Trace: F5.**
`Query.clone()` only shallow-copies `table_map`, sharing its list values, and
`change_aliases` mutates those lists in place. The explicit
`{table: aliases.copy() ...}` is therefore necessary to protect the original
rhs; `table_map` values are always lists, so `list.copy()` is valid.

### K4 — Keep excluding the base table from the bump
**Trace: F6.**
The merge relies on lhs and rhs sharing the base-table alias; relabelling it
would dangle rhs's base references. `exclude={rhs.base_table}` is necessary and
correct, and non-base joins still reference the base correctly.

### K5 — Keep the parameter rename `outer_query` → `other_query`
**Trace: F12.**
The name is now accurate for both call sites (subquery resolution and combine),
and the rename is safe because both existing callers pass it positionally.

### K6 — Keep the `change_aliases` assertion and its new comment
**Trace: F13, F15.**
The assertion is a valid invariant the fix upholds; the comment addresses the
explicit request in PROBLEM.md to document why keys/values must be disjoint.

### K7 — No code change for the "minimal repro doesn't crash here" observation
**Trace: F2.**
The literal snippet's lhs is base-only and yields an empty `change_map` on this
version, so it does not crash; the crash needs the lhs to contribute a
non-shared join. This shapes how a regression test must be written but requires
no source change — the fix already handles the general crashing case (F1).

### K8 — No change for surrounding interactions
**Trace: F7, F8, F10, F14.**
Prefix selection (F7), AND-connector coverage (F8), unaffected existing
`bump_prefix` callers (F10), and join-promotion / refcount / ordering
interactions (F14) were all verified to behave correctly; nothing needed
changing.

## Net effect
The V1 logic stands; V2 only narrows when the (already-correct) bump runs (C1)
and clarifies a docstring (C2). Both are transparent to query results and SQL.
