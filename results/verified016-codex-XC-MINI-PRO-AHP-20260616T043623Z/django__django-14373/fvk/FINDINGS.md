# FVK Findings

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## F-01: Pre-V1 `Y` output was not four digits for years below 1000

Classification: code bug, fixed by V1.

Evidence: prompt E-01 and docs/source obligations E-02/E-03 in `fvk/SPEC.md`.

Concrete input: `year = 42`, formatting with `Y`.

Observed before V1: `DateFormat.Y()` returned integer `42`; through
`Formatter.format()`, `str(42)` produced a two-character output.

Expected: a four-character zero-padded output representing the same year,
`0042`.

Resolution: V1 changes `DateFormat.Y()` to `return '%04d' % self.data.year`.
This discharges PO-01 through PO-03 in `fvk/PROOF_OBLIGATIONS.md`.

## F-02: V1 satisfies the `Y` method and formatting obligations

Classification: confirmed fix.

Evidence: proof obligations PO-01, PO-02, and PO-03.

Reasoning: within the date-year domain `1 <= year <= 9999`, Python's `%04d`
formatting yields a decimal string with at least four characters, padded with
leading zeroes when the shortest decimal representation has fewer than four
digits. Since all in-domain years are at most four digits, the result is exactly
four characters.

Resolution: no V2 source edit required.

## F-03: Direct `DateFormat.Y()` return type changes from `int` to `str`

Classification: compatibility note, accepted.

Evidence: E-01 and E-03 require leading zeroes at the method/specifier level;
E-05 found no in-repo direct callers or overrides; PO-05 covers public
compatibility.

Concrete input: `year = 4`, direct call to `DateFormat(obj).Y()`.

Observed before V1: integer `4`.

Expected by public intent: string-like four-digit representation `0004`.

Resolution: keep V1. Returning an integer would make the required leading zeroes
unrepresentable for direct method calls and would leave the method-level
contract unmet.

## F-04: Adjacent `o` year specifier was considered but not changed

Classification: underspecified adjacent behavior, not a V1 blocker.

Evidence: `DateFormat.o()` returns `self.data.isocalendar()[0]`, and docs show
`o` as an ISO-8601 week-numbering year. The public issue, title, and changed
method docstring identify `Y`, not `o`, as the four-digit zero-padded
obligation.

Concrete input: a date whose ISO week-numbering year is below 1000.

Observed in current source: `o` would be stringified from an integer by
`Formatter.format()`.

Expected: not established by this issue's public intent. A broader date-format
audit should ask whether `o` must mirror `Y`'s four-digit padding for ISO years.

Resolution: no source edit in this pass. This finding blocks using the present
proof to certify `o`, but it does not block confirming V1 for `Y`.

## F-05: No execution or machine proof was performed

Classification: proof status caveat.

Evidence: benchmark instructions prohibit running tests, Python, or K tooling.

Impact: the proof is constructed from public intent and source inspection, not
machine-checked. Test removal is not justified.

Resolution: keep all tests. The exact proof commands are written in
`fvk/PROOF.md` for a future environment that can run them.
