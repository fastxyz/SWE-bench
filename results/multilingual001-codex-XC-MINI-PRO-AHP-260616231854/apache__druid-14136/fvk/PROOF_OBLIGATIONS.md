# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Domain And Selection Invariant

- Claim: query intervals satisfy `QS <= QE`, zero-length intervals are allowed, and selected holder intervals satisfy `HS < QE` and `QS < HE`.
- Source: E-001, E-003, E-009.
- Discharge: the K claims require these facts explicitly; production code obtains selected holders from the existing `timelineInterval.overlaps(interval)` scan and stores only positive-duration adjusted timeline intervals.
- Status: discharged for the clipping proof domain.

## PO-002: Empty Selected List

- Claim: if the initial scan selects no holders, lookup returns an empty list.
- Source: code path `if (retVal.isEmpty()) return retVal;`.
- Discharge: claim C-EMPTY.
- Status: discharged.

## PO-003: First Holder Start Clipping

- Claim: for a selected first holder `[FS,FE]`, returned first start is `max(QS,FS)` and the interval remains valid.
- Source: E-004 and V1 endpoint check `interval.getStart().isAfter(firstEntry.getInterval().getStart())`.
- Discharge: if `QS > FS`, V1 constructs `[QS,FE]`; selected invariant gives `QS < FE`. If `QS <= FS`, V1 leaves `[FS,FE]`.
- Status: discharged.

## PO-004: Last Holder End Clipping

- Claim: for a selected last holder `[LS,LE]`, returned last end is `min(QE,LE)` and the interval remains valid.
- Source: E-005 and V1 endpoint check `interval.getEnd().isBefore(lastEntry.getInterval().getEnd())`.
- Discharge: if `QE < LE`, V1 constructs `[LS,QE]`. When first and last are distinct holders, the selected invariant gives `LS < QE`. When they are the same holder and PO-003 already changed the start to `QS`, the query-domain fact `QS <= QE` gives validity, including the zero-length case `QS = QE = T`. If `LE <= QE`, V1 leaves `[LS,LE]`.
- Status: discharged.

## PO-005: Zero-Length Interior Query

- Claim: for `QS = QE = T` and selected `[HS,HE]` with `HS < T < HE`, lookup returns `[T,T]`.
- Source: E-001, E-002, E-005.
- Discharge: PO-003 changes start to `T`; PO-004 then changes end to `T` because `T < HE`. The removed query-side `overlaps` guard can no longer block the second step.
- Status: discharged.

## PO-006: Holder Frame Condition

- Claim: clipping preserves true interval, version, partition object, holder count, and selected order.
- Source: E-007.
- Discharge: V1 only replaces `TimelineObjectHolder` instances at index `0` and `retVal.size() - 1`, passing through `getTrueInterval()`, `getVersion()`, and `getObject()`. It does not add, remove, or reorder entries.
- Status: discharged.

## PO-007: Public Compatibility And Other Overlap Audit

- Claim: V1 does not break public lookup consumers and no searched sibling overlap use still performs the reported positive-range expansion.
- Source: E-006 and E-008.
- Discharge: method signatures and holder shape are unchanged; callsites still consume `holder.getInterval()`; searched sibling overlap uses do not produce a new non-zero interval from a zero-length query.
- Status: discharged by source audit, not by K proof.
