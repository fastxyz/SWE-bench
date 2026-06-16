# FVK Findings

Status: constructed for audit, not machine-checked.

## F-001: Legacy join collapse violates public intent

Classification: code bug resolved by V1.

Input shape: a query with two `FilteredRelation` aliases on the same relation
path, such as `relation_zone=FilteredRelation("myrelation__nested",
condition=Q(myrelation__nested__zone=F("zone")))` and
`relation_all=FilteredRelation("myrelation__nested",
condition=Q(myrelation__nested__is_all=True))`, with later references to both
aliases.

Observed before V1: the second alias could reuse the first join because
`Query.join()` compared joins with `Join.equals()`, which ignores
`filtered_relation`.

Expected from SPEC E1-E6: each strong-distinct filtered alias receives its own
join and ON-clause filter.

Evidence: SPEC E1-E6, PROOF_OBLIGATIONS PO-NORMAL-DISTINCT and
PO-SQL-OBSERVABLE.

Resolution: V1 changes normal `Query.join()` reuse to use `j == join`, which
includes `filtered_relation` in `Join.identity`.

## F-002: FilteredRelation condition resolution must still use weak path reuse

Classification: required preservation, discharged by V1.

Input shape: compiling a `FilteredRelation` condition such as
`Q(book__title__contains="Alice")` while rendering the JOIN for
`book_title_alice=FilteredRelation("book", ...)`.

Observed risk: changing all equality checks to strong equality would prevent
the condition's plain `book__...` lookup from reusing the filtered join being
compiled, because the condition lookup candidate has no `filtered_relation`
object.

Expected from SPEC E5/E8: while compiling the ON condition, the condition lookup
reuses only aliases in `filtered_relation.path`, comparing by weak structural
join equality.

Evidence: SPEC E7/E8, PROOF_OBLIGATIONS PO-FILTERED-PATH-REUSE and
PO-REUSE-SET-SCOPE.

Resolution: V1 threads `reuse_with_filtered_relation=True` through
`build_filtered_relation_q() -> build_filter() -> setup_joins() -> join()` and
uses `Join.equals()` only in that opted-in path.

## F-003: No public compatibility blocker found

Classification: compatibility audit pass.

Input shape: existing internal source callsites of `Query.join()`,
`Query.build_filter()`, and `Query.setup_joins()`.

Observed in source: callsites use keyword arguments or fewer positional
arguments; no override definitions were found under `repo/`.

Expected from SPEC Public Compatibility Audit: defaulted internal parameters do
not alter existing callers.

Evidence: SPEC Public Compatibility Audit, PROOF_OBLIGATIONS
PO-CALLSITE-COMPATIBILITY.

Resolution: no source change beyond V1 is required.

## F-004: Full SQL compiler/database behavior is outside the mini-model

Classification: proof capability boundary, not a code bug.

The constructed proof models the property axis that caused the bug:
alias-map reuse and alias-to-filter binding. It does not machine-check Django's
full compiler, database execution, SQL quoting, join promotion, or row
cardinality semantics.

Evidence: SPEC Domain And Limits, PROOF_OBLIGATIONS PO-SQL-OBSERVABLE.

Guidance: keep integration tests for `FilteredRelation`, including the public
hint's regression shape. Do not remove tests based on this constructed proof
unless the emitted K artifacts are made concrete and `kprove` returns `#Top`.

## Proof-derived findings from /verify

No new code bug was found beyond F-001. The proof obligations force exactly the
V1 distinction between strong normal equality and weak path-limited equality
during ON-clause condition compilation. V1 satisfies those obligations, so V2
keeps the source unchanged.

