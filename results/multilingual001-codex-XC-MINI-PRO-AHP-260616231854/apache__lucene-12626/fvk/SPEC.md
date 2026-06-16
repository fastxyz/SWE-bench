# FVK Spec: SegmentInfos.replace userData

Status: constructed, not machine-checked.

## Scope

The formalization target is the V1 repair unit:
`repo/lucene/core/src/java/org/apache/lucene/index/SegmentInfos.java`, method
`SegmentInfos.replace(SegmentInfos other)`, plus the immediate `IndexWriter` initialization path
that calls it for an explicit `IndexCommit`.

The full Lucene index writer is outside this mini-semantics. The modeled observable is the commit
state that `replace` is responsible for: segment list, `lastGeneration`, commit `userData`, and the
frame fields that the method intentionally preserves.

## Intent Spec

For any non-null `other` `SegmentInfos`, `this.replace(other)` must:

1. Replace this instance's segment list with `other.asList()`.
2. Set this instance's `lastGeneration` to `other.lastGeneration`.
3. Set this instance's commit `userData` to `other.userData`.
4. Preserve this instance's write-once metadata not intentionally replaced by this method:
   `generation`, `version`, and `counter`.
5. Not change public APIs, signatures, file formats, or tests.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "`replace` method doesn't set `userData` with the new user data from `other`" | `replace` must transfer `userData` from `other`. | Encoded in claim `SEGMENTINFOS-REPLACE-SPEC`. |
| E2 | prompt | Proposed fix adds `userData = other.userData;` | Direct assignment is within the public issue's intended repair. | Accepted. |
| E3 | source comment | `CommitUserData` stores data passed to `IndexWriter#setLiveCommitData` in `segments_N`. | `userData` is commit metadata, not unrelated writer-local state. | Encoded as postcondition. |
| E4 | source code | `IndexWriter` reads `oldInfos` from an explicit commit and calls `segmentInfos.replace(oldInfos)`. | The replacement commit's metadata must become the active metadata before `commitUserData` is initialized. | Encoded in adequacy notes. |
| E5 | source code | `replace` comment: "keeps generation, version, counter so that future commits remain write once." | `generation`, `version`, and `counter` are frame conditions. | Encoded in claim. |
| E6 | source code | `DataInput.readMapOfStrings()` returns an immutable map. | Direct assignment of `other.userData` from `readCommit` is not a new mutability hazard in the explicit-commit path. | Supports keeping V1 unchanged. |

## Formal Model

The mini-K model represents a `SegmentInfos` object as:

```text
si(segments, lastGeneration, userData, generation, version, counter)
```

The claim in `fvk/segmentinfos-replace-spec.k` states:

```text
replace(
  si(selfSegments, selfLast, selfUser, selfGeneration, selfVersion, selfCounter),
  si(otherSegments, otherLast, otherUser, otherGeneration, otherVersion, otherCounter))
=>
  si(otherSegments, otherLast, otherUser, selfGeneration, selfVersion, selfCounter)
```

This claim is property-complete for the reported defect because the model distinguishes a passing
instance (`selfUser` becomes `otherUser`) from the pre-fix failing instance (`selfUser` remains
`selfUser` when `selfUser != otherUser`).

## Adequacy Audit

The formal claim matches the intent spec:

- Segment replacement: pass. The claim sets receiver `segments` to `otherSegments`.
- `lastGeneration` replacement: pass. The claim sets receiver `lastGeneration` to `otherLast`.
- `userData` replacement: pass. The claim sets receiver `userData` to `otherUser`.
- Write-once frame fields: pass. The claim preserves receiver `generation`, `version`, and
  `counter`.
- Direct assignment vs copy: pass. The public issue's fix uses direct assignment, and local source
  conventions (`setUserData`, commit point storage, immutable read maps) do not require a defensive
  copy for this method.

## Compatibility Audit

No public symbol, signature, virtual dispatch call, file format, or serialized field ordering is
changed. The edit only adds an assignment to an existing field in a package-private method.

## Exact Commands To Machine-Check Later

These commands are recorded only; they were not run.

```sh
kompile fvk/mini-java-segmentinfos.k --backend haskell
kast --backend haskell fvk/segmentinfos-replace-spec.k
kprove fvk/segmentinfos-replace-spec.k
```
