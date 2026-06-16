# FVK Specification - apache__lucene-13494

Status: constructed, not machine-checked.

## Scope

Target production code:

- `repo/lucene/facet/src/java/org/apache/lucene/facet/StringValueFacetCounts.java`

Audited public methods:

- `getTopChildren(int topN, String dim, String... path)`
- `getAllChildren(String dim, String... path)`
- `getSpecificValue(String dim, String... path)`
- `getAllDims(int topN)` as a caller of `getTopChildren`

The formal model abstracts away Lucene doc-values iteration, priority-queue label
ordering, and exact label materialization. Those are not the reported failure axis.
The modeled observable is whether public accessors dereference absent count storage
or return the zero-count result required by the issue.

## Intent Spec

I-001. A `StringValueFacetCounts` instance built from a valid `FacetsCollector` whose
query matched no documents must be usable by `getTopChildren`.

I-002. For a valid field and empty path, `getTopChildren(topN, field)` with
`topN > 0` must return a `FacetResult` whose `childCount` is `0` when no documents
matched.

I-003. The empty-result behavior must not throw `NullPointerException` because count
storage was not allocated.

I-004. Because `StringValueFacetCounts` treats the field itself as the dimension,
the valid field remains a valid dimension even when the matching hit set is empty.

I-005. Existing validation behavior remains in force: invalid `topN`, invalid
dimension, or invalid path shape should still fail before result construction.

I-006. For `getSpecificValue`, the inherited `Facets` contract says an absent path
returns `-1`; an indexed value with no matching hits has count `0`.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| E-001 | problem | "query not matching any docs" | The no-hit collector path is in domain. |
| E-002 | problem | "I expect to get `0` as a facet count, but get NPE" | The expected observable is zero count, not an exception. |
| E-003 | problem | `assertEquals(top.childCount, 0)` | `getTopChildren` must return a result with `childCount == 0`. |
| E-004 | problem | `counts.getTopChildren(10, "field")` | Valid dimension is the field name. |
| E-005 | source | `Facets.getSpecificValue`: "Returns -1 if this path doesn't exist, else the count." | Existing term plus no hits returns count `0`; absent term returns `-1`. |
| E-006 | source | Constructor branch `totalHits == 0` leaves both count stores null for high cardinality. | "No count storage" is a legitimate empty state, not inherently corruption. |
| E-007 | source | Low-cardinality constructor delays dense allocation until `countOneSegment`. | Low-cardinality no-hit collectors can also leave count storage null. |
| E-008 | source | `validateTopN` and field/path validators run at accessor entry. | V1 must preserve validation order for invalid inputs. |

## Formal Spec English

F-001. If storage is `none`, `totalDocCount == 0`, `topN > 0`, `dim == field`,
and `path` is empty, then `getTopChildren` returns `FacetResult(field, [], 0,
[], 0)`.

F-002. If storage is `none`, `totalDocCount == 0`, `dim == field`, and `path` is
empty, then `getAllChildren` returns `FacetResult(field, [], 0, [], 0)`.

F-003. If storage is `none`, `totalDocCount == 0`, `dim == field`, and the
specific value exists in the field ordinal table, then `getSpecificValue` returns
`0`.

F-004. If the specific value does not exist in the field ordinal table, then
`getSpecificValue` returns `-1`, regardless of count storage.

F-005. If storage is dense or sparse, the public methods do not take the
empty-result shortcut; the pre-existing dense/sparse counting paths remain the
source of child labels and counts.

F-006. `getAllDims(topN)` delegates to `getTopChildren(topN, field)` and therefore
inherits F-001 for the empty valid field result.

F-007. Invalid `topN`, dimension, or path shape is outside the successful result
claims. The Java implementation validates these before the empty-storage guard.

## Spec Audit

| Formal item | Intent coverage | Verdict |
| --- | --- | --- |
| F-001 | E-001 through E-004 directly require zero child count for no hits. | Pass |
| F-002 | Same no-hit state; `getAllChildren` has the same non-zero-child contract shape. | Pass |
| F-003 | E-005 says existing paths return their count; no hits means count zero. | Pass |
| F-004 | E-005 explicitly requires `-1` for absent paths. | Pass |
| F-005 | E-008 and minimal-change intent require not changing non-empty counting behavior. | Pass |
| F-006 | Source implementation delegates, so the proof obligation follows from F-001. | Pass |
| F-007 | E-008 supports preserving validation; the issue does not request invalid-input changes. | Pass |

No formal item is candidate-only or legacy-only. The only implementation-derived
abstraction is the `none` storage state, and E-006/E-007 show that state exists in
the source and is exactly the reported failure mechanism.

## Public Compatibility Audit

- No public method signature changed.
- No constructor signature changed.
- No return type changed.
- Two private helpers were added: `hasCountStorage()` and `emptyResult()`.
- Public callsites using `StringValueFacetCounts` continue to call the same
  constructors and `Facets` methods.
- `StringValueFacetCounts` still overrides the same `Facets` methods.

Verdict: no public compatibility issue found.

## Formal Core

The K model is in:

- `fvk/mini-java-facet.k`
- `fvk/string-value-facet-counts-spec.k`

Commands to run later, not executed in this session:

```sh
(cd fvk && kompile mini-java-facet.k --backend haskell)
(cd fvk && kast --backend haskell string-value-facet-counts-spec.k)
(cd fvk && kprove string-value-facet-counts-spec.k)
```
