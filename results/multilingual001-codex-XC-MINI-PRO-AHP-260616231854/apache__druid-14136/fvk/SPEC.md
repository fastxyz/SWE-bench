# FVK Spec

Status: constructed, not machine-checked. No tests or K tooling were run.

## Scope

This FVK pass audits the V1 change to `VersionedIntervalTimeline.lookup`, specifically the selected-holder clipping phase in `repo/processing/src/main/java/org/apache/druid/timeline/VersionedIntervalTimeline.java`.

The model abstracts each `TimelineObjectHolder` to its adjusted holder interval `[start,end)`. It frames true interval, version, object payload, and holder order because the production code reconstructs holders with those fields unchanged during clipping.

## Public Intent Ledger

The standalone ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The key obligations are:

- E-001 and E-002: zero-length query intervals are valid and must not scan positive-duration data.
- E-004 and E-005: clipping must not depend on `queryInterval.overlaps(holderInterval)` because the query interval can be zero-length after first-holder clipping.
- E-007: clipping should preserve holder payload fields.
- E-008: callsites consume `holder.getInterval()` as the segment descriptor interval.

## Contract

Let the requested interval be `Q = [QS,QE]`, with `QS <= QE`.

Let `H` be the ordered holder list selected by the initial lookup scan. The selected-list invariant is:

- For each selected holder interval `[HS,HE]`, `HS < QE` and `QS < HE` under Joda's existing selection behavior.
- The holder interval has positive duration before clipping, because timeline maps store only positive-duration adjusted intervals.

The clipping phase must return:

- `[]` when `H` is empty.
- For a single selected holder `[HS,HE]`, `[max(QS,HS), min(QE,HE)]`.
- For multiple selected holders, first interval start clipped to `max(QS,firstStart)`, last interval end clipped to `min(QE,lastEnd)`, and middle intervals unchanged.
- For the issue case `Q = [T,T]` and selected `[HS,HE]` where `HS < T < HE`, the returned interval is `[T,T]`.

Frame condition:

- Holder count, order, true intervals, versions, and partition objects are preserved.

## Formal Artifacts

- `fvk/mini-java-interval-timeline.k` contains the minimal K semantics for the clipping fragment.
- `fvk/versioned-interval-timeline-spec.k` contains claims for empty, single-holder, zero-length, and multi-holder clipping.
- `fvk/FORMAL_SPEC_ENGLISH.md` paraphrases the claims.
- `fvk/SPEC_AUDIT.md` confirms the claims match public intent.
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` checks changed public symbols and callsites.

## Adequacy

The abstraction is adequate for this issue because the bug manipulates only returned holder interval endpoints. The model keeps the endpoint values observable and distinguishes the failing pre-fix result `[T,HE]` from the required `[T,T]`. Payload fields are intentionally framed because the production change does not alter them and the public issue gives no intent to change them.
