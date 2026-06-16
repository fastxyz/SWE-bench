# Formal Spec English

Status: constructed, not machine-checked.

## Claim SFS-SCORE-LOOP

If the local CV object is already checked/reusable and contains `S > 0` splits,
then running `scoreLoop(C)` for any `C >= 0` candidate score calls terminates
with exactly `C` additional successful scoring events. The checked CV object is
not consumed by any score call.

## Claim SFS-FIT-ONESHOT

For any one-shot iterable split source with `S > 0` splits and any candidate
count `C >= 0`, `fit(oneShot(S), C)` first converts the CV source to a reusable
checked object and then completes `C` successful candidate score calls. It does
not reach the empty-score failure state.

## Claim SFS-FIT-ITERABLE

For any list-like iterable split source with `S > 0` splits and any candidate
count `C >= 0`, `fit(iterable(S), C)` converts it to a reusable checked object
and completes all `C` scoring calls.

## Claim SFS-FIT-SPLITTER

For any CV splitter object with `S > 0` splits and any candidate count `C >= 0`,
`fit(splitter(S), C)` uses an equivalent reusable checked object and completes
all `C` scoring calls.

## Claim SFS-FIT-INT

For any integer CV value represented by `intCv(S)` with `S >= 2`, and any
candidate count `C >= 0`, `fit(intCv(S), C)` uses `S` reusable splits and
completes all `C` scoring calls.

## Claim SFS-FIT-NONE

For `cv=None`, represented by `noneCv`, and any candidate count `C >= 0`,
`fit(noneCv, C)` uses the default five reusable splits and completes all `C`
scoring calls.

## Claim SFS-RAW-ONESHOT-FAILS

The pre-fix shape `rawFit(oneShot(S), C)` with `S > 0` and `C >= 2` can reach an
empty-score failure after the first scoring call consumes the one-shot source and
a later score call observes zero remaining splits. This claim localizes the
reported symptom; it is not an intended behavior claim.
