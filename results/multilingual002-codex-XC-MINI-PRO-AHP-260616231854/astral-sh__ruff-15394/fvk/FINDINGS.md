# FINDINGS

Status: constructed for audit, not machine-checked.

## FVK-F1: Reported parenthesized spread left a closing parenthesis

- Evidence: I1, I2.
- Input: `{"data": [], **({"count": 1 if include_count else {}})}`
- V0 observed behavior: the fix removed `**({` and the inner `}`, but left the matching `)`, producing `"count": 1 if include_count else {})`.
- Expected behavior: remove both the opening wrapper before `{` and the matching closing wrapper after `}`.
- Classification: code bug in fix construction.
- Resolution: fixed by counting opening parentheses between `**` and `{` and deleting the same number of closing parentheses after the inner `}`.
- Proof obligations: PO1, PO2, PO3.

## FVK-F2: V1 still mishandled empty spread separators

- Evidence: I3, I5, I6.
- Input: `{"x": 1, **({}), "y": 2}`
- V1 observed behavior by edit construction: deleting only the empty spread expression leaves the previous item separator and the following item separator, yielding the shape `{"x": 1, , "y": 2}`.
- Expected behavior: remove the empty spread as a dict item, including one adjacent separator, yielding `{"x": 1, "y": 2}`.
- Additional affected shapes: `{**{}, "y": 2}`, `{"x": 1, **{}}`, `{**{},}`, and parenthesized variants such as `{**({}), "y": 2}`.
- Classification: boundary-case code bug in the empty branch.
- Resolution: fixed by adding `empty_spread_edit`, which selects the deletion range by item position.
- Proof obligations: PO4, PO5, PO6.

## FVK-F3: Machine proof and tests were not run

- Evidence: benchmark no-execution rule.
- Input: all proof obligations.
- Observed: this pass can construct the proof and inspect code, but cannot run `kprove`, `cargo test`, Python, or Ruff.
- Expected: artifacts must list the commands and reason about expected outcomes without executing them.
- Classification: proof honesty gate / residual verification risk, not a code bug.
- Resolution: `PROOF.md` includes exact commands and labels the proof constructed, not machine-checked.
- Proof obligations: all.

## No Open Code Findings

After the V2 patch, the FVK audit did not identify another source change justified by the public intent and current proof obligations.
