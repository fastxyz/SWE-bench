# FVK Spec

Status: constructed for FVK audit, not machine-checked.

## Scope

This spec audits the V1 fix for `django.utils.http.parse_http_date()` in
`repo/django/utils/http.py`. The target behavior is the year-normalization
branch for parsed years below 100. The surrounding parser behavior is covered
by frame conditions because V1 did not change regex matching, month/day/time
parsing, epoch conversion, exceptions, or public signatures.

The formal core is:

- `fvk/mini-http-date.k`
- `fvk/http-date-spec.k`

These files model the arithmetic slice:

```text
current_year = datetime.datetime.utcnow().year
current_century = current_year - (current_year % 100)
year = current_century + parsed_year
if year > current_year + 50:
    year -= 100
```

## Intent Ledger

The complete evidence ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical
entries are summarized here.

| ID | Provenance | Obligation |
| --- | --- | --- |
| E2 | RFC quote in problem | RFC850 two-digit years more than 50 years in the future roll back to the most recent past year with the same last two digits. |
| E3 | Problem description | Reject fixed `00-69` / `70-99` expansion. |
| E4 | Public hint | The check is relative to the current year. |
| E5 | Public hint | Use UTC current year, not local date. |
| E7/E8 | Code docstring | Preserve accepted HTTP-date formats and UTC epoch return shape. |
| E10 | Public test | Preserve existing broad `year < 100` normalization compatibility for parsed year `0037`. |
| E11 | Public callsites | Preserve signatures and integer/`None` consumer protocol. |

## Formal Contract

For `0 <= YY < 100` and `CY >= 100`:

```text
CC = CY - (CY mod 100)
CANDIDATE = CC + YY

normalize2(YY, CY) =
    CANDIDATE       if CANDIDATE <= CY + 50
    CANDIDATE - 100 if CANDIDATE > CY + 50
```

`CY` is the UTC current year. `YY` is the parsed numeric year below 100.
The `CY >= 100` side condition reflects the real current-year domain needed
for a one-century rollback to remain a positive calendar year.

The rollover result has the same last two digits as `YY`, is less than `CY`,
and is the most recent past year with those last two digits.

## Adequacy

The plain-English paraphrase in `fvk/FORMAL_SPEC_ENGLISH.md` matches the
intent-only obligations in `fvk/INTENT_SPEC.md`; `fvk/SPEC_AUDIT.md` records
all audited claims as pass.

The proof is intentionally partial over the parser: it proves the changed
arithmetic contract and frames all unchanged parsing and timestamp conversion
behavior. This abstraction preserves the defect axis because it distinguishes
the legacy failing instance `YY=69, CY=2018 -> 2069` from the required result
`1969`.

## Compatibility

`fvk/PUBLIC_COMPATIBILITY_AUDIT.md` records no signature, dispatch, return
shape, or callsite incompatibility. V1 changes only the intended timestamp
value for affected parsed years.
