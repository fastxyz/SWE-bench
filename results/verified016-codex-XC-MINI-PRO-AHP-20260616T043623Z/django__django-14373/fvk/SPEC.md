# FVK Specification: `DateFormat.Y()`

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## Scope

This FVK pass audits the V1 fix for
`django.utils.dateformat.DateFormat.Y()` and the observable path through
`Formatter.format()` when the format string contains `Y`. The target source is
`repo/django/utils/dateformat.py`.

The proof domain is a `datetime.date` or `datetime.datetime`-like object whose
`year` is an integer in Python's supported date range, `1 <= year <= 9999`.
That domain is intent-derived from Django's date formatting API and the Python
date objects used by it, not from V1's implementation.

## Public Evidence Ledger

E-01, prompt: "DateFormat.Y() is not zero-padded." and "The Y specifier for
django.utils.dateformat.DateFormat is supposed to always return a four-digit
year padded with zeros." Semantic obligation: the `Y` specifier must produce a
four-digit, zero-padded year for every in-domain year, including years below
1000. Status: encoded in PO-01, PO-02, and the K claim `DATEFORMAT-Y`.

E-02, docs: `repo/docs/ref/templates/builtins.txt` lists `Y` as "Year, 4
digits." Semantic obligation: template/date formatting output for `Y` has four
digits, not merely the shortest decimal rendering. Status: encoded in PO-02 and
PO-03.

E-03, source comment/name: `DateFormat.Y()` has the method docstring "Year, 4
digits; e.g. '1999'." Semantic obligation: the method-level formatter for `Y`
is itself responsible for the four-digit representation. Status: encoded in
PO-01.

E-04, implementation: `Formatter.format()` appends
`str(getattr(self, piece)())` for each recognized format character. Semantic
obligation: the value returned by `DateFormat.Y()` is the value exposed by
`format(value, "Y")` after string conversion. This is implementation evidence
for the proof path, not an independent expected value. Status: encoded in
PO-02.

E-05, implementation compatibility search: no in-repo direct calls to
`DateFormat.Y()` or subclasses/overrides of `DateFormat` were found under
`repo/django` or `repo/tests`; the in-repo public path constructs
`DateFormat(value)` and calls `.format()`. Semantic obligation: no public
in-repo callsite is broken by making `Y()` return a string. Status: encoded in
PO-05.

E-06, adjacent formatter: `DateFormat.o()` is also year-shaped, but the public
issue and the `DateFormat.Y()` docstring explicitly identify `Y` as the
four-digit zero-padded formatter. Semantic obligation: this FVK pass does not
derive a required source change for `o`; a broader audit of all year specifiers
should ask that question directly. Status: recorded as Finding F-04.

## Intent-Only Spec

I-01. For every in-domain `year`, `DateFormat(obj).Y()` returns the four-digit
zero-padded decimal representation of `obj.year`.

I-02. For every in-domain `year`, `dateformat.format(obj, "Y")` returns the
same four-digit zero-padded decimal representation.

I-03. Boundary years below 1000 remain in domain and require leading zeros:
year `1` has length 4 and numeric value 1, year `42` has length 4 and numeric
value 42, and year `999` has length 4 and numeric value 999.

I-04. Years 1000 through 9999 remain unchanged as four visible digits; the fix
must not truncate or otherwise alter them.

I-05. Non-`Y` format specifiers and the dispatcher's escaping/time-specifier
checks are frame conditions for this issue and must be unchanged.

## Formal Model

The supporting formal core is in:

- `fvk/mini-dateformat.k`
- `fvk/dateformat-y-spec.k`

The mini model represents the string output by `yearText(LEN, VALUE)`, where
`LEN` is the visible decimal string length and `VALUE` is the represented
integer. This preserves the property under audit: a failing pre-V1 output for
year 42 is `yearText(2, 42)`, while the required output is
`yearText(4, 42)`.

The model abstracts Python's `'%04d' % year` operation as `pad4(year)`, with the
in-domain semantic rule:

```k
rule <k> pad4(Y:Int) => yearText(4, Y) ... </k>
  requires (1 <=Int Y) andBool (Y <=Int 9999)
```

## Formal English Round Trip

Claim `DATEFORMAT-Y`: If `Y` is an integer date year with
`1 <= Y <= 9999`, evaluating the modeled current body of `DateFormat.Y()` reaches
`yearText(4, Y)`.

Claim `FORMAT-Y`: If `Y` is an integer date year with `1 <= Y <= 9999`,
evaluating the modeled `Formatter.format()` path for a single `Y` specifier
reaches `yearText(4, Y)`.

Frame condition `NON-Y-FRAME`: No formal claim rewrites or depends on any
formatter method other than `Y()`, and V1 leaves the dispatcher and all other
specifier methods unchanged.

## Adequacy Audit

I-01 versus `DATEFORMAT-Y`: pass. The claim states exactly the four-digit
method-level obligation for all valid date years.

I-02 versus `FORMAT-Y`: pass. The claim follows the public dispatcher path and
requires the same padded observable output.

I-03 versus `DATEFORMAT-Y` and `FORMAT-Y`: pass. The claims quantify over the
full valid year range, including all years below 1000.

I-04 versus `DATEFORMAT-Y` and `FORMAT-Y`: pass. The `yearText(4, Y)` result
also applies to years 1000 through 9999.

I-05 versus `NON-Y-FRAME`: pass. V1 changes only `DateFormat.Y()`.

E-06 versus this pass's scope: ambiguous but non-blocking. `o` is adjacent, but
the prompt and the method-level contract under repair identify `Y`. No proof
obligation in this pass is allowed to prove or disprove `o`.

## Public Compatibility Audit

Changed public symbol: `django.utils.dateformat.DateFormat.Y`.

Observed in-repo callsites: `DateFormat(value).format(...)` and
`dateformat.format(value, format_string)`. `Formatter.format()` already converts
specifier method results with `str()`, so returning a string for `Y()` is
compatible with the observable public formatting path.

Observed overrides/subclasses: no `DateFormat` subclasses or `Y()` overrides
were found in `repo/django` or `repo/tests`.

Return-type note: direct external calls to `DateFormat(obj).Y()` may observe a
type change from `int` to `str`. This is intentional and required by E-01 and
E-03 because an integer cannot represent leading zeroes.

## Verdict

V1 is adequate for the specified issue. No additional source change is justified
by the FVK findings or proof obligations.
