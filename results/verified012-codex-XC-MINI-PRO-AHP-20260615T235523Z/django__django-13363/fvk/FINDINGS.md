# FVK Findings

Status: constructed, not machine-checked.

## F1 - TruncDate discarded explicit tzinfo before V1

Classification: code bug, fixed by V1.

Input:

- `USE_TZ=True`;
- current timezone name `UTC`;
- explicit `tzinfo` name `America/New_York`;
- `TruncDate("start_at", tzinfo=America/New_York)`.

Observed before V1:

- `TruncDate.as_sql()` computed `tzname` from
  `timezone.get_current_timezone_name()`;
- backend call received `UTC`.

Expected:

- backend date cast receives `America/New_York`.

Evidence:

- Public ledger E1, E2, E4, E6, E7, E10.
- Proof obligations PO1 and PO4.

V1 status:

- Closed. `TruncDate.as_sql()` now calls `self.get_tzname()`, which selects
  the explicit timezone when `USE_TZ=True` and `self.tzinfo` is present.

## F2 - TruncTime had the same explicit tzinfo loss

Classification: code bug, fixed by V1.

Input:

- `USE_TZ=True`;
- current timezone name `UTC`;
- explicit `tzinfo` name `America/New_York`;
- `TruncTime("start_at", tzinfo=America/New_York)`.

Observed before V1:

- `TruncTime.as_sql()` computed `tzname` from
  `timezone.get_current_timezone_name()`;
- backend call received `UTC`.

Expected:

- backend time cast receives `America/New_York`.

Evidence:

- Public ledger E3, E4, E6, E7, E10.
- Proof obligations PO1 and PO5.

V1 status:

- Closed. `TruncTime.as_sql()` now calls `self.get_tzname()`, which selects
  the explicit timezone when `USE_TZ=True` and `self.tzinfo` is present.

## F3 - Visible public tests do not cover explicit tzinfo on TruncDate/TruncTime

Classification: test gap, no production-code change.

Input:

- Public tests cover default `TruncDate` and `TruncTime`, and explicit
  `tzinfo` for `Extract`, generic `Trunc`, and subclasses such as
  `TruncYear`.

Observed:

- No visible public test directly asserts
  `TruncDate("start_datetime", tzinfo=melb)` or
  `TruncTime("start_datetime", tzinfo=melb)`.

Expected:

- A future visible test should assert explicit timezone priority for both cast
  subclasses.

Evidence:

- Public ledger E11.
- Proof obligations PO4 and PO5 identify the missing behavioral points.

V1 status:

- No test files were modified because the task forbids test edits.

## Proof-derived findings

The constructed claims discharge all branch combinations in the audited domain:
explicit timezone, fallback current timezone, and disabled timezone support for
both date and time casts. No additional production-code defect was found.

The only residual risk is the standard FVK MVP caveat: the proof is constructed
but not machine-checked because K tooling was not run.

