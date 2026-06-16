# FVK Spec: apache__lucene-11760

Status: constructed, not machine-checked. No tests, Java code, Python, `kompile`, or `kprove` were
run.

## Target

The audited unit is the anonymous `IntervalIterator` returned by
`IntervalBuilder.NO_INTERVALS.intervals(...)` in
`repo/lucene/queries/src/java/org/apache/lucene/queries/intervals/IntervalBuilder.java`.

V1 changes only document-iterator state:

- adds `private int doc = -1`;
- returns `doc` from `docID()`;
- assigns and returns `doc = NO_MORE_DOCS` from `nextDoc()`;
- assigns and returns `doc = NO_MORE_DOCS` from `advance(int)`.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E-001 | problem | "IntervalBuilder.NO_INTERVALS returns wrong docId when unpositioned" | The defect is specifically the document id state of the empty interval iterator before positioning. | Encoded by PO-001. |
| E-002 | problem | "DocIdSetIterators should return -1 when they are unpositioned" | `docID()` must return `-1` before any `nextDoc()` or `advance(int)` call. | Encoded by PO-001. |
| E-003 | problem | "NO_INTERVALS always returns NO_MORE_DOCS" | The pre-fix hard-coded `NO_MORE_DOCS` initial state is the behavior to reject, not preserve. | Finding F-001. |
| E-004 | problem | "empty interval query ... combined in a conjunction" | A no-match interval source must be safe to combine with other unpositioned iterators. | Encoded by PO-005. |
| E-005 | source docs | `DocIdSetIterator.docID()` documents `-1` before `nextDoc()`/`advance()` and `NO_MORE_DOCS` after exhaustion. | Empty iterators need a two-state document-position model: unpositioned then exhausted. | Encoded by PO-001 through PO-004. |
| E-006 | source code | `DocIdSetIterator.empty()` uses an `exhausted` state and returns `-1` before exhaustion. | This is local corroboration for the default empty-iterator state machine. | Encoded by PO-001 through PO-004. |
| E-007 | source code | `ConjunctionDISI.createConjunction` checks all sub-iterators are on the same current doc id and throws otherwise. | In a conjunction setup, a V1 empty iterator must agree with normal unpositioned siblings at `-1`. | Encoded by PO-005. |
| E-008 | source code | `IntervalBuilder.analyzeText` returns `NO_INTERVALS` when there are no tokens. | Stopword-only analyzed text can produce this empty source. | Scope evidence for F-001 and F-002. |

## Intent-Only Contract

For every `IntervalIterator it` returned by `IntervalBuilder.NO_INTERVALS.intervals(field, ctx)`:

1. Initial document state: before `nextDoc()` or `advance(int)`, `it.docID() == -1`.
2. Empty iteration by `nextDoc()`: from the initial state, `it.nextDoc() == NO_MORE_DOCS`, and after
   that call `it.docID() == NO_MORE_DOCS`.
3. Empty iteration by `advance(target)`: for every in-domain target `target >= 0`,
   `it.advance(target) == NO_MORE_DOCS`, and after that call `it.docID() == NO_MORE_DOCS`.
4. No-match frame: the iterator still has no document or interval matches; `cost()` and
   `matchCost()` remain zero, `nextInterval()` returns `NO_MORE_INTERVALS`, and `matches(...)`
   remains `null`.
5. Conjunction compatibility: a conjunction that combines this empty iterator with a normal
   unpositioned iterator must not fail its initial "same doc id" check because of the empty
   iterator. The shared initial doc id is `-1`.

## Formal Model

The constructed K fragment models only the document-position state needed for the defect:

- state cell `<doc>` contains the current `docID()` value;
- initial constructed empty iterator state is `<doc> -1 </doc>`;
- `docID` returns the state unchanged;
- `nextDoc` sets `<doc>` to `NO_MORE_DOCS` and returns `NO_MORE_DOCS`;
- `advance(TARGET)` sets `<doc>` to `NO_MORE_DOCS` and returns `NO_MORE_DOCS` for `TARGET >= 0`;
- `sameDoc(D1, D2)` models the conjunction setup equality check.

The formal files are:

- `fvk/mini-lucene-iterator.k`
- `fvk/no-intervals-spec.k`

Exact commands to machine-check later, not run in this session:

```sh
kompile fvk/mini-lucene-iterator.k --backend haskell
kast --backend haskell fvk/no-intervals-spec.k
kprove fvk/no-intervals-spec.k
```

## Formal Spec English

- Claim C-001: In the initial empty iterator state, `docID()` returns `-1`.
- Claim C-002: In the initial empty iterator state, `nextDoc()` returns `NO_MORE_DOCS` and changes
  the stored document state to `NO_MORE_DOCS`.
- Claim C-003: In the initial empty iterator state, `advance(target)` returns `NO_MORE_DOCS` and
  changes the stored document state to `NO_MORE_DOCS` for all `target >= 0`.
- Claim C-004: In the exhausted state, `docID()` returns `NO_MORE_DOCS`.
- Claim C-005: Two unpositioned iterators with doc id `-1` satisfy the conjunction setup same-doc
  predicate.
- Claim C-006: A pre-fix pair consisting of `NO_MORE_DOCS` and `-1` does not satisfy that same-doc
  predicate.

## Adequacy Audit

| Claim | Intent match | Audit |
|---|---|---|
| C-001 | E-001, E-002, E-005 | Pass. This is the reported required behavior. |
| C-002 | E-004, E-005, E-006 | Pass. Empty iterator exhaustion follows the `DocIdSetIterator` contract and empty-iterator witness. |
| C-003 | E-004, E-005, E-006 | Pass. `advance(int)` has the same exhaustion obligation on the empty iterator. |
| C-004 | E-005 | Pass. This is the documented exhausted state. |
| C-005 | E-004, E-007 | Pass. It models why V1 is safe for conjunction setup. |
| C-006 | E-003, E-007 | Pass as diagnostic only. It formalizes the pre-fix mismatch the issue reports. |

## Compatibility Audit

No public method signature, return type, class hierarchy, dispatch shape, or storage format changed.
The only source change is a private field inside an anonymous iterator and the state returned by
`docID()` before and after document advancement. Existing interval-position methods are deliberately
framed unchanged because the public issue and conjunction failure mode concern `DocIdSetIterator`
document state.
