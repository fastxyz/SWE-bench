# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent, source inspection, and proof obligations only.

## F-001: Pre-fix lookup expands a zero-length interior query into a positive holder interval

- Classification: code bug, resolved by V1.
- Evidence: `benchmark/PROBLEM.md` says the zero-length interval query "matches all data after `2016-06-27T00:00:11.080Z`" and identifies `interval.overlaps(lastEntry.getInterval())` as the failed guard.
- Input shape: query `[T,T]`; selected adjusted holder `[HS,HE]` with `HS < T < HE`.
- Observed pre-fix behavior: after first-holder clipping, holder becomes `[T,HE]`; the last-holder end clipping is skipped because `query.overlaps([T,HE])` is false when both starts are `T` and query length is zero.
- Expected behavior: returned holder interval `[T,T]`, so downstream segment descriptors do not request a positive time range.
- Proof obligations: PO-003, PO-004, PO-005.
- V1 status: discharged. V1 removes the query-side overlap guards and clips by endpoint comparison.

## F-002: V1 preserves required holder framing

- Classification: confirmed behavior.
- Evidence: V1 reconstructs only the first and/or last `TimelineObjectHolder` interval while passing through true interval, version, and object.
- Input shape: any non-empty selected holder list.
- Observed V1 behavior: holder count and order are unchanged; middle holders are unchanged; first/last payload fields are unchanged.
- Expected behavior: same.
- Proof obligations: PO-006.
- V1 status: discharged. No additional source edit required.

## F-003: Constructed proof is not machine-checked

- Classification: proof capability / environment limitation.
- Evidence: the task forbids running K tooling, and the FVK MVP labels proofs "constructed, not machine-checked."
- Impact: proof and test-redundancy conclusions must remain conditional on later `kompile`/`kprove` execution.
- Proof obligations: all.
- V1 status: no source edit required; keep tests and treat the proof as constructed evidence only.

## F-004: Other searched overlap uses do not show the same positive-range expansion pattern

- Classification: audit finding, no code bug found.
- Evidence: production searches found remaining query-side or interval-side `overlaps` uses in locks, compaction, metadata, and query runners. The callsites relevant to lookup consume `holder.getInterval()`, which V1 now clips. Other checked uses either reject work when overlap is false, preserve the zero-length interval, or operate on non-query lock/compaction intervals.
- Input shape: zero-length query interval.
- Observed V1 behavior: no additional searched use expands `[T,T]` to `[T,U]`.
- Expected behavior: no positive-range expansion from a zero-length query.
- Proof obligations: PO-007.
- V1 status: no additional source edit required.
