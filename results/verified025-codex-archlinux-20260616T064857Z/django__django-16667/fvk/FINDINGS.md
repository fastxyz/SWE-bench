# FVK Findings

Status: constructed, not machine-checked.

## F-001 - Resolved code bug: uncaught overflow on complete split date input

- Evidence: E-001, E-002, E-003.
- Input: `my_date_year="1234567821345678"`, `my_date_month="1"`, `my_date_day="1"`.
- Pre-V1 observed behavior: `datetime.date(int(y), int(m), int(d))` could raise `OverflowError`, escaping `form.is_valid()` and causing an internal server error.
- Expected behavior: return the pseudo-ISO invalid value `"1234567821345678-1-1"` so `DateField` validation can reject it as an invalid date.
- Classification: code bug, needed code guard.
- Status: resolved by PO-001. V1 catches `OverflowError` in the same handler as `ValueError`.

## F-002 - Preservation finding: existing invalid-date behavior still stands

- Evidence: E-004, E-005.
- Input: `field_year=""`, `field_month="12"`, `field_day="1"`.
- Expected behavior: return `"0-12-1"` rather than `None`, because all components are present but the date is invalid or incomplete.
- Audit result: V1 changes only the exception tuple for the existing pseudo-ISO branch. It does not change the pseudo-ISO expression or the all-present guard.
- Classification: compatibility preservation.
- Status: satisfied by PO-002 and PO-006.

## F-003 - Preservation finding: valid, all-empty, and missing-component branches are unchanged

- Evidence: E-005, E-006.
- Inputs:
  - valid complete triple such as `("2000", "12", "1")`;
  - all blank components `("", "", "")`;
  - missing component such as absent `field_year`, present month and day.
- Expected behavior:
  - valid complete triples return a formatted date string;
  - all blank components return `None`;
  - missing components return `data.get(name)`.
- Audit result: V1 changes no branch condition and no return expression for these paths.
- Classification: compatibility preservation.
- Status: satisfied by PO-003, PO-004, PO-005, and PO-006.

## F-004 - Proof caveat: constructed proof was not executed

- Evidence: FVK verify honesty gate.
- Input: all modeled request-string inputs.
- Observed verification state: the proof and K commands are constructed but not run, per benchmark instruction and FVK MVP status.
- Expected action: keep any test-removal recommendation conditional on future `kprove` success.
- Classification: proof capability gap, not a source-code bug.
- Status: documented by PO-007 and `fvk/PROOF.md`.

## Open Code Findings

No open source-code findings remain for the public issue scope. The FVK pass confirms V1 as V2.

