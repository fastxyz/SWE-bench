# FVK Findings

Status: constructed from source and public evidence, not machine-checked.

## F-001: Pre-fix chained filters cause token-proportional join growth

Input: admin search with related `search_fields`, for example
`clientoffice__name`, and a multi-word search term.

Observed in pre-fix source: each parsed token executed
`queryset = queryset.filter(or_queries)` inside the token loop.

Expected from public intent: the search predicate should have the documented
AND-of-ORs semantics without adding another related join chain per token.

Classification: code bug / performance-relevant query-shape bug.

Resolution: fixed by V2. `get_search_results()` now accumulates term clauses
and calls `queryset.filter(*term_queries)` once.

Related proof obligations: O3, O4, O5.

## F-002: V1 had an unnecessary nested AND wrapper

Input: any nonempty token list.

Observed in V1: V1 called `queryset.filter(models.Q(*term_queries))`. This was
semantically correct and still one queryset filter call, but `QuerySet.filter()`
itself wraps positional arguments in a `Q`, creating an extra nested AND node.

Expected from the proof obligation: all term clauses should be submitted to one
filter operation with no unnecessary wrapper.

Classification: proof-simplifying cleanup, not a user-visible bug.

Resolution: V2 uses `queryset.filter(*term_queries)`.

Related proof obligations: O4, O5.

## F-003: Legacy multi-valued relation semantics are not preserved

Input: a multi-word search where different related rows could satisfy different
words through the same multi-valued relation.

Observed in legacy chained filters: separate filter calls can allocate separate
aliases, so different related rows may satisfy different tokens.

Expected from public intent: the docs describe one SQL `WHERE` clause with
ANDed per-word OR clauses, and the issue explicitly requires removing the
per-word chained filter pattern.

Classification: considered semantic ambiguity / rejected legacy behavior.

Resolution: no code change beyond V2. The ambiguity does not block V2 because no
public evidence requires the legacy different-related-row behavior.

Related proof obligations: O3, O4, O5.

## F-004: Machine checking and runtime SQL inspection were not run

Input: all proof obligations.

Observed: this workspace forbids running tests, Python, or K tooling.

Expected: FVK artifacts must record commands and reason about expected outcomes
without executing them.

Classification: verification honesty gate / residual risk.

Resolution: `PROOF.md` includes exact `kompile`, `kast`, and `kprove` commands,
all labeled constructed, not machine-checked. No source change required.

Related proof obligations: all, especially O5.
