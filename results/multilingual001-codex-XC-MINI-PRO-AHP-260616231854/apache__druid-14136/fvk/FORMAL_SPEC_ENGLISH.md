# Formal Spec English

Status: constructed from K claims, not machine-checked.

## Claim C-EMPTY

For any query interval `[QS,QE]`, clipping an empty selected holder list returns an empty list.

## Claim C-SINGLE-CLIP

For a selected single holder interval `[HS,HE]` with `HS < QE` and `QS < HE`, `lookupClip(QS,QE,[HS,HE])` returns exactly one holder interval `[max(QS,HS), min(QE,HE)]` and preserves the holder payload fields.

## Claim C-MULTI-CLIP

For a selected ordered holder list with at least two intervals, the first holder start is replaced by `max(QS, firstStart)`, the last holder end is replaced by `min(QE, lastEnd)`, and all middle holder intervals and payload fields are preserved.

## Claim C-ZERO-INTERIOR

For a zero-length query `[T,T]` and a selected holder whose original adjusted interval strictly contains `T`, `lookupClip(T,T,[HS,HE])` returns `[T,T]`.

## Claim C-FRAME

The clipping phase does not change holder count, selected order, true intervals, versions, or partition objects.

## Claim C-COMPAT

The public lookup method signatures and `TimelineObjectHolder` constructor shape remain unchanged; callsites that consume `holder.getInterval()` continue to receive an `Interval`, but now it is bounded by the query interval after clipping.
