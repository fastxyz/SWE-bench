# Proof Obligations

Status: constructed obligations; not machine-checked.

## PO1: Reversed Positive Log Limits Preserve Order

Precondition: `HIGH > LOW > 0`, both finite.

Obligation: `LogLocator.nonsingular(HIGH, LOW)` returns `(HIGH, LOW)`.

Evidence: E1, E2, E3, E4, E7.

Discharge status: discharged by the constructed proof. V1 records the reversed
input with `swapped`, performs existing checks on sorted values, and restores
the original order in the final return.

## PO2: Axis-Level Inversion Follows From Stored Order

Precondition: PO1 plus a log-scaled axis.

Obligation: `set_ylim(HIGH, LOW)` and `set_xlim(HIGH, LOW)` store
`(HIGH, LOW)` in the relevant `viewLim` interval, so `Axis.get_inverted()` is
true.

Evidence: E4, E5, E6, E8.

Discharge status: discharged by composition of PO1 and PO3.

## PO3: Positive Log Range Clamp Is Identity

Precondition: both bounds are positive.

Obligation: `LogScale.limit_range_for_scale` returns each bound unchanged and
does not reorder the pair.

Evidence: E8.

Discharge status: discharged by source inspection and encoded in the mini-K
model.

## PO4: Normal Ordered Positive Limits Stay Normal

Precondition: `0 < LOW < HIGH`.

Obligation: `LogLocator.nonsingular(LOW, HIGH)` returns `(LOW, HIGH)`.

Evidence: E5, E7.

Discharge status: discharged by the constructed proof. The `swapped` flag is
false, so the final return keeps the increasing order.

## PO5: Singular and Invalid Branches Are Not Accidentally Reinterpreted

Precondition: equal positive limits, nonfinite limits, or all-nonpositive data.

Obligation: the fix does not claim inversion semantics for equality or invalid
log-domain inputs. Existing fallback/expansion behavior remains available.

Evidence: E4, E8, existing source behavior.

Discharge status: discharged as a frame condition. No V2 code edit is required.

## PO6: Tick Generation Still Handles Inverted Intervals

Precondition: the stored interval is reversed and positive.

Obligation: tick calculation can still compute with sorted bounds internally
without mutating the stored interval.

Evidence: E9.

Discharge status: discharged by source inspection; `tick_values` sorts local
variables when `vmax < vmin`.

## PO7: Public Compatibility

Precondition: existing callers use `LogLocator.nonsingular(vmin, vmax)`.

Obligation: the fix must not change signatures, return shape, or virtual
dispatch requirements.

Evidence: public compatibility audit.

Discharge status: discharged. Signature and tuple return shape are unchanged.

