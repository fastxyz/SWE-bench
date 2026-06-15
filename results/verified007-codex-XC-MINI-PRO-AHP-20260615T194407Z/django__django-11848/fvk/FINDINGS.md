# Findings

Status: constructed for FVK audit, not machine-checked.

## Summary

No new code defect was found in V1. The FVK audit confirms V1 against the
specified proof obligations and keeps the source unchanged.

## F-001: Legacy Fixed Cutoff Violated RFC850 Intent

Classification: code bug, resolved by V1.

Evidence: E2 and E3; PO-002 through PO-004.

Concrete input:

```text
current UTC year CY = 2018
RFC850 parsed two-digit year YY = 69
legacy observed year = 2069
expected year = 1969
```

V1 status: resolved. `parse_http_date()` now computes the current UTC century,
forms `2069`, detects `2069 > 2018 + 50`, and subtracts 100.

## F-002: Local Current Date Would Be a Boundary Bug

Classification: needed code guard/source choice, resolved by V1.

Evidence: E5; PO-005.

Problem: using local `date.today().year` or `datetime.now().year` could differ
from GMT around New Year's for deployments outside UTC, making HTTP-date
parsing timezone-dependent.

V1 status: resolved. The code uses `datetime.datetime.utcnow().year`.

## F-003: Boundary Is Strictly Greater Than 50 Years

Classification: boundary condition, confirmed by V1.

Evidence: E2; PO-002 and PO-003.

Concrete input:

```text
CANDIDATE = CY + 50
expected = CANDIDATE
incorrect alternative = CANDIDATE - 100
```

V1 status: confirmed. The code rolls back only for `year > current_year + 50`.

## F-004: Broad `year < 100` Branch Is Compatibility-Derived

Classification: compatibility decision, confirmed by V1.

Evidence: E10; PO-007.

Observation: RFC850 is the format with a two-digit year, but the pre-existing
implementation also normalized any parsed numeric year below 100, including
asctime input such as `0037`.

Decision: keep the broad branch. Narrowing it to the RFC850 regex would be an
additional behavior change not required by the issue and contradicted by public
test evidence. The FVK proof records this as compatibility-derived, not
RFC-derived.

## Proof-Derived Findings from `/verify`

The constructed proof creates no additional code-bug findings. All proof
obligations are discharged over the arithmetic normalization model, with parser
behavior outside the changed branch framed as unchanged.

Residual caveat: the proof is constructed but not machine-checked. The emitted
`kompile`, `kast`, and `kprove` commands in `PROOF.md` must be run before
calling the result machine-verified or removing any tests.

