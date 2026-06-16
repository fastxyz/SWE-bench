# Findings

Status: FVK audit findings from formalization and constructed verification.

## F1: V1 Addresses the Reported Regression

Input: finite positive reversed limits such as `set_ylim(100000, 1)` on a
log-scaled axis.

Observed before V1: `LogLocator.nonsingular` sorted the pair to `(1, 100000)`,
so `Axes.set_ylim` stored an increasing interval and `Axis.get_inverted()` was
false.

Expected: the stored interval is `(100000, 1)` and the axis is inverted.

V1 status: fixed. This is PO1 + PO2.

## F2: The Relevant Domain Is Finite Positive Unequal Limits

Input: nonpositive explicit log limits.

Observed behavior: `Axes.set_xlim` / `Axes.set_ylim` warn and replace the
nonpositive explicit bound with the old bound before locator normalization.

Expected: unchanged by this issue. The public bug report uses positive data and
the log scale domain is positive.

V1 status: no source change needed. This is PO5.

## F3: No Compatibility Finding Blocks V1

Input: existing public callers of `LogLocator.nonsingular`.

Observed: the method signature and return shape are unchanged. Axis limit
callers benefit from preserved order, and tick generation sorts local variables
when it needs increasing bounds.

Expected: no callsite or override update.

V1 status: confirmed. This is PO6 + PO7.

## Proof-Derived Findings

No proof-derived code bug was found. The constructed proof exposes one honesty
condition: the K artifacts were not machine-checked because this session forbids
running K tooling. Test removal or proof-confidence upgrades must wait for the
commands in `PROOF.md` to return `#Top`.

