# FVK Proof Obligations

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## PO-01: Method-level `Y()` padding

For every in-domain date year `Y` such that `1 <= Y <= 9999`,
`DateFormat(obj).Y()` must return the four-digit zero-padded decimal
representation of `Y`.

Source: SPEC evidence E-01 and E-03.

Formal claim: `DATEFORMAT-Y` in `fvk/dateformat-y-spec.k`.

V1 discharge: `return '%04d' % self.data.year`.

Status: discharged by construction.

## PO-02: Formatter integration for a single `Y` specifier

For every in-domain date year `Y`, `dateformat.format(obj, "Y")` must expose the
same four-digit zero-padded representation as `DateFormat(obj).Y()`.

Source: SPEC evidence E-01, E-02, and E-04.

Formal claim: `FORMAT-Y` in `fvk/dateformat-y-spec.k`.

V1 discharge: `Formatter.format()` invokes `DateFormat.Y()` for the `Y` format
character and stringifies its result; the result is already the required string.

Status: discharged by construction.

## PO-03: Boundary coverage for all years below 1000

The proof must cover the entire family of valid pre-1000 years, not only one
example. For every `Y` where `1 <= Y <= 999`, the result has visible length 4
and numeric value `Y`.

Source: SPEC evidence E-01 and the FVK family/boundary rule.

Formal claim: included in the quantified domain of `DATEFORMAT-Y` and
`FORMAT-Y`.

V1 discharge: `%04d` pads all one-, two-, and three-digit positive years with
leading zeroes.

Status: discharged by construction.

## PO-04: Non-regression for years 1000 through 9999

For every `Y` where `1000 <= Y <= 9999`, the result remains the ordinary
four-digit decimal representation of `Y`; the fix must not truncate, add extra
characters, or change the numeric value.

Source: SPEC evidence E-02 and E-03.

Formal claim: included in the quantified domain of `DATEFORMAT-Y` and
`FORMAT-Y`.

V1 discharge: `%04d` leaves four-digit years as four digits.

Status: discharged by construction.

## PO-05: Public compatibility of the source change

The change must not require changes to public in-repo callsites, subclass
overrides, or the `Formatter.format()` dispatcher.

Source: SPEC evidence E-04 and E-05.

Formal/compatibility claim: public compatibility audit in `fvk/SPEC.md`.

V1 discharge: only `DateFormat.Y()` changed; the dispatcher already calls
`str()` on formatter results, and no direct in-repo callers or overrides were
found.

Status: discharged by source inspection.

## PO-06: Frame condition for unrelated specifiers

The proof must not justify changes to unrelated format specifiers or time/date
validation behavior.

Source: intent-only spec I-05 in `fvk/SPEC.md`.

Formal claim: `NON-Y-FRAME` in `fvk/SPEC.md`.

V1 discharge: the source diff is limited to `DateFormat.Y()`.

Status: discharged by diff inspection.

## PO-07: Termination

`DateFormat.Y()` contains no loop or recursion. `Formatter.format()` loops over
the finite split result of the provided format string, but this V1 proof only
models the single-character `"Y"` path.

Source: implementation control flow.

Status: no termination proof attempted or needed for the audited method-level
obligation; broader dispatcher termination is outside this issue.
