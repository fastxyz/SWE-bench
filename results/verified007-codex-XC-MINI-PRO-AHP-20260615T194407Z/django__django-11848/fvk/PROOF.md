# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, or `kprove`
command was run.

## Claim Proven

For every current UTC year `CY >= 100` and parsed numeric year
`0 <= YY < 100`, V1 normalizes the year as:

```text
CC = CY - (CY mod 100)
CANDIDATE = CC + YY

result =
    CANDIDATE       if CANDIDATE <= CY + 50
    CANDIDATE - 100 if CANDIDATE > CY + 50
```

This is exactly the RFC850 two-digit-year obligation derived from the public
issue and hints.

## Symbolic Execution Sketch

### Non-rollover branch

Initial symbolic state:

```text
YY in [0, 99]
CY >= 100
CANDIDATE = CY - (CY mod 100) + YY
CANDIDATE <= CY + 50
```

V1 executes:

```text
current_year = CY
current_century = CY - (CY mod 100)
year = YY + current_century = CANDIDATE
if year > CY + 50: false
```

The branch exits with `year = CANDIDATE`, satisfying PO-002.

### Rollover branch

Initial symbolic state:

```text
YY in [0, 99]
CY >= 100
CANDIDATE = CY - (CY mod 100) + YY
CANDIDATE > CY + 50
```

V1 executes:

```text
current_year = CY
current_century = CY - (CY mod 100)
year = YY + current_century = CANDIDATE
if year > CY + 50: true
year = CANDIDATE - 100
```

The result has the same last two digits because subtracting 100 preserves the
value modulo 100. It is in the past because `CANDIDATE <= CC + 99` and
`CC <= CY`, so `CANDIDATE - 100 <= CC - 1 < CY`. No later year with those
last two digits is in the past: the next such year is `CANDIDATE`, which is
future by the branch condition.

This satisfies PO-003.

### Discriminator

For `CY = 2018`, `YY = 69`:

```text
CC = 2000
CANDIDATE = 2069
CY + 50 = 2068
2069 > 2068
result = 2069 - 100 = 1969
```

This satisfies PO-004 and distinguishes V1 from the legacy fixed cutoff.

## Parser Frame Proof

The V1 diff touches only the `year < 100` normalization branch. It does not
change:

- the RFC1123, RFC850, or asctime regexes;
- month lookup in `MONTHS`;
- day, hour, minute, or second parsing;
- `datetime.datetime(year, month, day, hour, min, sec)` validation;
- `calendar.timegm(result.utctimetuple())`;
- `parse_http_date_safe()`.

Therefore PO-006 holds by syntactic frame inspection.

## Machine-Check Commands

These commands are emitted for a later environment with K installed. They were
not run in this session.

```sh
cd fvk
kompile mini-http-date.k --backend haskell
kast --backend haskell http-date-spec.k
kprove http-date-spec.k
```

Expected machine-check result after successful proof discharge: `#Top`.

## Test-Redundancy Recommendation

No tests were edited. Any removal would be conditioned on the K proof being
machine-checked.

Potentially subsumed after machine-checking:

- point tests asserting the year-normalization formula for in-domain RFC850
  two-digit years;
- boundary point tests such as `CANDIDATE = CY + 50`;
- discriminator tests such as `CY=2018, YY=69`.

Keep:

- invalid-format and invalid-date tests;
- integration tests through cache/middleware/static-file callsites;
- tests for parser formats and epoch conversion outside the modeled arithmetic
  slice;
- any timezone-boundary tests until the UTC source is also covered by an
  executable integration proof.
