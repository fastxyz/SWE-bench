# FVK Findings

Status: constructed, not machine-checked.

## F-001: Pre-fix midpoint permits an out-of-bounds helper read

Classification: code bug, fixed by V1.

Input class: `sentenceStarts.length == 2`, `preceding` reaches the search branch, and
`pos` is in or after the second sentence.

Observed before V1: `currentSentence = sentenceStarts.length / 2` gives
`currentSentence = 1`. The helper is called with range `0..1`; in a non-base frame it can
evaluate `sentenceStarts[currentSentence + 1]`, i.e. `sentenceStarts[2]`, outside valid
indices `[0, 1]`.

Expected: no `ArrayIndexOutOfBoundsException`; the issue explicitly says the midpoint
should be `(sentenceStarts.length - 1) / 2`.

Trace: E-001, E-002, E-003; PO-001, PO-002; K claim `PRE_FIX_COUNTEREXAMPLE`.

Status after audit: discharged by V1.

## F-002: Helper safety depends on a non-base frame invariant

Classification: proof side condition, discharged.

Input class: any recursive `moveToSentenceAt` frame reached from `preceding`.

Required invariant: when `minSentence < maxSentence`, `currentSentence < maxSentence`.
Together with `maxSentence < sentenceStarts.length`, this implies
`currentSentence + 1` is a valid array index before the right-branch test reads it.

V1 establishes the invariant initially because for `N > 1`,
`(N - 1) / 2 < N - 1`; for `N == 1`, the helper frame is a base frame. The left and
right recursive midpoint updates preserve the invariant or recurse directly into a base
frame.

Trace: E-001, E-002; PO-003, PO-004; K claims `PRECEDING_V1_SAFE`, `MOVE_SAFE`.

Status after audit: discharged by V1; no source change needed.

## F-003: Public compatibility is preserved

Classification: compatibility finding, no issue.

V1 changes only an internal expression in an existing public override. It does not change
the signature, return type, declared exceptions, class hierarchy, field layout, or caller
protocol.

Trace: E-005; PO-005; `PUBLIC_COMPATIBILITY_AUDIT.md`.

Status after audit: no source change needed.

## F-004: Return-offset semantics are intentionally not re-specified by this FVK pass

Classification: underspecified broader behavior, non-blocking for this issue.

The public issue concerns an exception caused by the midpoint and names the intended
midpoint expression. The constructed K model abstracts concrete return offsets and proves
the exception-safety property that distinguishes V1 from the pre-fix code. Existing local
public tests document current `preceding` return behavior, and V1's single-expression
change preserves it.

Trace: E-001, E-002, E-005; SPEC_AUDIT row "Concrete return offsets".

Status after audit: no source change justified.
