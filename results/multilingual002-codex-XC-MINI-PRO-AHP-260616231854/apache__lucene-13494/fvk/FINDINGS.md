# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent,
source inspection, and proof-obligation construction only.

## F-001 - Resolved Code Bug: No-Hit Storage Can Be Null

Input:

- An index has a valid string doc-values field, such as `field = foo`.
- Search uses `MultiCollectorManager(FacetsCollectorManager, TopScoreDocCollectorManager)`.
- Query is `MatchNoDocsQuery`, so no documents match.
- Caller constructs `StringValueFacetCounts(state, facetsCollector)` and calls
  `getTopChildren(10, "field")`.

Observed before V1:

- `getTopChildren` takes the dense branch when `sparseCounts == null`.
- `denseCounts` can also be null because no counting path allocated storage.
- The method dereferences `denseCounts.length` and throws `NullPointerException`.

Expected:

- A valid `FacetResult` with `childCount == 0`, no labels, and total count `0`.

V1 status:

- Fixed. `getTopChildren` now checks `hasCountStorage() == false` after validation
  and returns `emptyResult()`.

Proof obligations:

- PO-001, PO-002, PO-004.

## F-002 - Resolved Completeness Gap: Same Empty State Affects Related Accessors

Input:

- Same no-hit storage state as F-001.
- Caller invokes `getAllChildren("field")` or `getSpecificValue("field", "foo")`.

Observed before V1:

- `getAllChildren` could dereference `denseCounts.length`.
- `getSpecificValue` could dereference `denseCounts[ord]` for an indexed term.

Expected:

- `getAllChildren("field")` returns an empty `FacetResult`.
- `getSpecificValue("field", "foo")` returns `0` when `foo` exists but has no
  matching hits.
- `getSpecificValue("field", missing)` still returns `-1`.

V1 status:

- Fixed. The same no-storage guard covers `getAllChildren` and existing terms in
  `getSpecificValue`; absent terms still return `-1` before the storage check.

Proof obligations:

- PO-003, PO-005, PO-006.

## F-003 - Confirmed: Empty Storage Is a Valid Representation

Evidence:

- High-cardinality construction explicitly sets both count stores null on
  `totalHits == 0`.
- Low-cardinality construction delays dense allocation until a segment with hits is
  counted.

Conclusion:

- The source should not treat `denseCounts == null && sparseCounts == null` as an
  illegal state after an empty collection. Returning an empty result from public
  accessors is the intent-compatible interpretation.

Proof obligations:

- PO-001.

## F-004 - Confirmed: No New Source Change Needed Beyond V1

Audit result:

- The V1 guard is placed after the existing public argument validation and before
  any dense-store dereference.
- Dense and sparse non-empty storage paths remain unchanged.
- No public API or override contract changed.

Decision:

- Keep V1 unchanged.

Proof obligations:

- PO-002 through PO-008.

## Residual Risks

- This FVK pass is constructed, not machine-checked. K commands are emitted in
  `SPEC.md` and `PROOF.md` but not run.
- The mini-K model abstracts Lucene priority-queue ordering and doc-values
  iteration. Those are outside the reported no-hit/null-storage failure axis.
- Termination and performance are not proved. The changed methods add constant-time
  guards before existing loops.
