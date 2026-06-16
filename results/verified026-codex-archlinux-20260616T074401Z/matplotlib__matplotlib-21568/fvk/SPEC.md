# FVK Spec: matplotlib__matplotlib-21568

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The audited unit is `matplotlib.dates._wrap_in_tex(text)` and its observable
use by date formatters when TeX rendering is enabled:

- `DateFormatter.__call__`
- `AutoDateFormatter.__call__`, through `DateFormatter`
- `ConciseDateFormatter.format_ticks`, including `offset_string`

The code under audit has no loop. The proof obligations are deterministic
string-transformation obligations and formatter frame obligations.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | issue | "Datetime axis with usetex is unclear" | TeX-rendered datetime tick labels must remain visually clear. | Encoded |
| E2 | issue | "spacing from version 3.3 in a tex format" | TeX mode should not collapse date and time fields that were separated in normal text. | Encoded |
| E3 | issue hint | "protecting spaces didn't happen properly" | Spaces inside TeX math wrapping must be represented by a TeX spacing command. | Encoded |
| E4 | issue workaround | `replace('-', '{-}').replace(':', r'{:}').replace(' ', r'\;')` | Dashes, colons, and spaces are the separator family needing literal/protected TeX form. | Encoded |
| E5 | source docs | Date formatter `usetex` parameter enables "TeX's math mode" | Only the TeX-rendering path should be changed; non-TeX labels remain plain formatter output. | Encoded |
| E6 | public tests | Existing expected strings keep `Jan` outside `\mathdefault` | Alphabetic date fragments outside math mode are existing public behavior. This does not conflict with E1-E4. | Encoded as compatibility frame |
| E7 | public tests | Existing expected strings contain raw spaces/colons in math chunks | SUSPECT legacy evidence because the issue reports exactly this spacing behavior as the bug. | Finding F2 |
| E8 | implementation | All date formatter TeX paths call `_wrap_in_tex` except user-supplied callable `AutoDateFormatter.scaled` entries | Fixing `_wrap_in_tex` covers built-in formatter strings; callable custom formatters remain caller responsibility per docstring. | Encoded |

## Intent-First Contract

Domain: formatted date label strings produced by Matplotlib date formatters for
TeX rendering. This includes ASCII digits, ASCII month/day words, dashes,
colons, literal spaces, decimal points, and other strftime punctuation. The
issue does not require `_wrap_in_tex` to become a general-purpose TeX escaper
for arbitrary user text containing every TeX special character.

For every in-domain string `text`, `_wrap_in_tex(text)` must produce a TeX
label whose math-mode chunks satisfy:

1. Every original `-` separator is represented as `{-}`.
2. Every original `:` separator is represented as `{:}`.
3. Every original literal space separator is represented as `\;`.
4. Alphabetic runs may remain outside `\mathdefault`, preserving the existing
   upright text behavior for month/day names.
5. Empty `$\mathdefault{}$` chunks introduced by alphabetic splitting are
   removed.

Formatter frame conditions:

1. With `usetex=False`, formatter output remains the raw `strftime` result.
2. With `usetex=True`, built-in date formatter labels and concise formatter
   offset strings are passed through `_wrap_in_tex`.
3. User-provided callable entries in `AutoDateFormatter.scaled` are not wrapped
   by this helper, matching the existing docstring that such callables are
   responsible for their own TeX handling.

## Formal Core

The K artifacts are:

- `fvk/mini-python-datewrap.k`
- `fvk/datewrap-spec.k`

The main formal claims are:

- `CLAIM-WRAP-IN-TEX`: `wrapInTex(T)` rewrites to `expectedWrap(T)`.
- `CLAIM-PROTECT-SEPARATORS`: `wrapInTex(T)` produces an output satisfying
  `protectsDateSeparators(T, OUT)`.
- `CLAIM-DATEFORMATTER-USETEX`: formatter output is wrapped when `usetex=True`.
- `CLAIM-DATEFORMATTER-NON-TEX`: formatter output is unchanged when
  `usetex=False`.

## V1 Verdict

V1 satisfies the intent-first contract. It adds colon and space protection to
the existing dash protection while preserving alphabetic splitting and all
public formatter call signatures. No V2 source edit is justified by the FVK
audit.
