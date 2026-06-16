# Constructed Proof

Status: constructed, not machine-checked. No K tooling was executed.

## Machine-check commands to run later

```sh
kompile fvk/mini-tzname.k --backend haskell
kast --backend haskell fvk/tzname-spec.k
kprove fvk/tzname-spec.k
```

Expected machine-check result after a real K run: `#Top` for all claims.

## Proof sketch

### Classifier proof

V2 defines `_tzname_delta_re` as the anchored numeric-offset family `^(UTC)?[+-]\d{2}(?::?\d{2})?$`. `_split_tzname_delta()` has two paths:

1. If the regex matches, return `(prefix or "", sign, offset)`.
2. If it does not match, return `(None, None, None)`.

Therefore `Etc/GMT-10` cannot produce a delta because it does not begin with the optional `UTC` prefix followed immediately by a numeric sign and two digits. Fixed offsets such as `+10`, `+1000`, `+10:00`, and `UTC+05:00` do produce deltas. This discharges `PO1` and `PO6`.

### PostgreSQL proof

PostgreSQL `_prepare_tzname_delta()` first calls `_split_tzname_delta()`.

- If `sign` is false, the function returns `tzname` unchanged. By the classifier proof, signed IANA names such as `Etc/GMT-10` take this path. This discharges `PO2`.
- If `sign` is `+`, the function changes it to `-`; if `sign` is `-`, it changes it to `+`; it then returns `prefix + sign + offset`. Since only fixed-offset strings have a sign in this branch, sign reversal is restricted to numeric offsets. This discharges `PO3`.

### MySQL and Oracle proof

MySQL and Oracle call `_split_tzname_delta()` and share the same branch structure:

- If no sign is returned, return `tzname` unchanged. Therefore `Etc/GMT-10` is not truncated.
- If a sign is returned, return `sign + offset`, intentionally dropping only the optional `UTC` prefix.

This discharges `PO2` and `PO4`.

### SQLite proof

SQLite uses `TIMEZONE_OFFSET_REGEX`, which matches the same fixed-offset family as the base backend helper. `_sqlite_datetime_parse()` only mutates `tzname` and applies `offset_delta` inside `if offset_match`.

- For `Etc/GMT-10`, `offset_match` is false, so no split or offset adjustment occurs; the original name is passed to `pytz.timezone(tzname)`.
- For fixed offsets, `tzname` becomes `UTC`, and `offset_delta` is added or subtracted according to the sign.

This discharges `PO5`.

## Adequacy and residual risk

The model does not execute Django SQL or database timezone conversion. That is adequate for this defect because the reported bad behavior is the Django-produced timezone string. Database timezone-table availability remains outside the proof and is recorded as `F4`.

The proof is partial over the modeled string-preparation functions. There are no loops in the modeled code. Termination follows from finite straight-line branches but was not machine-checked.

## Test-redundancy recommendation

No tests should be removed. This proof has not been machine-checked, and the task forbids test edits. Existing and future tests around timezone SQL generation should be kept until the K commands above are actually run and the broader backend test suite is available.
