# FORMAL_SPEC_ENGLISH.md

Status: constructed, not machine-checked.

## RESTORE-ONE

For every ordered leading-prefix list `P` and every core branch `ri`, the V1
descending prepend loop returns the ordered list `P ++ ri`.

## RESTORE-GENERAL

For every ordered leading-prefix list `P` and every branch list
`[r0, ..., rn]`, restoring the leading prefix produces:

```text
[P ++ r0, ..., P ++ rn]
```

It preserves branch count and the internal order of `P` and each `ri`.

## RESTORE-WITNESS

For `P = [rho, sigma]` and one empty core branch, fixed restoration produces
one branch `[rho, sigma]`.

## LEGACY-WITNESS

For `P = [rho, sigma]` and one empty core branch, the old left-to-right prepend
restoration produces one branch `[sigma, rho]`.

## Frame Condition

The proof does not claim to rederive the Kahane contraction coefficient or graph
walk. It proves only that the final restoration step preserves the leading free
prefix order for every branch.
