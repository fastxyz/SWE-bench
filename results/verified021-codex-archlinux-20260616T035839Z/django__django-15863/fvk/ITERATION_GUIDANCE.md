# Iteration Guidance

Status: constructed, not machine-checked.

## Code decision

Keep V1 unchanged. Findings F-001 and F-002, together with PO-1 through PO-3,
show that the Decimal precision defect is fixed by routing existing Decimal
instances directly to the existing Decimal rounding path.

## Rejected changes

Do not broaden the fix to `input_val = str(text)` for all inputs in this issue
pass. Finding F-003 and PO-4 show that the broader change is not required by
public intent and could alter non-Decimal behavior.

Do not edit tests in this task. PO-6 and the user instructions forbid it.

## Suggested future public tests

If tests are added in a normal development setting, add a focused regression
test equivalent to:

```python
floatformat(Decimal("42.12345678901234567890"), 20)
```

with expected output:

```text
42.12345678901234567890
```

Keep existing tests for localization, grouping, invalid suffixes, and Decimal
low-context behavior; they cover integration concerns outside this mini proof.

## Verification commands for a real environment

These commands are documentation only in this task:

```sh
kompile fvk/mini-floatformat.k --backend haskell
kast --backend haskell fvk/floatformat-spec.k
kprove fvk/floatformat-spec.k
```

Treat any test-redundancy recommendation as conditional on a successful
machine-check result.
