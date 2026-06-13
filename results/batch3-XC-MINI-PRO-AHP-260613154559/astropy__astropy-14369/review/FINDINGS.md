# Code review — V1 fix for astropy__astropy-14369

Scope reviewed: `astropy/units/format/cds.py` (`p_division_of_units` grammar change)
and `astropy/units/format/cds_parsetab.py` (`_tabversion` invalidation), plus their
interactions with the CDS writer, the PLY infrastructure, and the existing tests.

Legend for severity: **[blocking]**, **[improve]**, **[ok]** (confirmed correct /
no action needed).

---

## F1. Core correctness on the reported cases — [ok]
The issue is right-associative parsing of `/` chains: the old rule
`division_of_units : unit_expression DIVISION combined_units` let the right operand be
another division, so `J/m/s/kpc2` grouped as `J/(m/(s/kpc2)) = J·s/(m·kpc2)`.

V1 makes division left-recursive:
```
division_of_units : DIVISION unit_expression
                  | unit_expression DIVISION unit_expression
                  | division_of_units DIVISION unit_expression
```
Tracing `10+3J/m/s/kpc2`: factor `10**3 = 1000`; `J/m/s/kpc2` reduces left-to-right as
`((J/m)/s)/kpc2 = J/(m·s·kpc2)`; result `1000 J / (kpc2 m s)`. `10-7J/s/kpc2` →
`1e-7 J / (kpc2 s)`. Both match the issue's "expected". The action body is unchanged
(`p[2]**-1` for leading slash, `p[1]/p[3]` for the binary forms), which is correct
under left recursion because `p[1]` is the accumulated left result. **Correct.**

## F2. The parser-table regeneration is actually required and it works — [ok, but see F8]
`astropy/utils/parsing.py::yacc` builds the parser with `optimize=True`. In
`astropy/extern/ply/yacc.py:3294`, `if optimize or (read_signature == signature)` means
that when `optimize` is truthy PLY loads the cached `cds_parsetab.py` **verbatim and
never checks the grammar signature**. Therefore a grammar edit in `cds.py` alone has no
effect unless the cached table is invalidated. V1 sets `_tabversion='0.0'`; on load,
`LRTable.read_table` (line 1987) raises `VersionError`, which `yacc()` catches
(line 3302) and then rebuilds the parser from the current grammar, and rewrites the
table when the directory is writable (`write_table`, line 3484; `IOError` there is
caught at 3487 and the in-memory parser is used). Verified the rebuilt parser uses the
new grammar (`bind_callables`/`LRParser` at 3498-3499). **The mechanism is sound and is
the in-place equivalent of the documented "delete the file and rebuild" workflow.**

Failure-mode check: if regeneration somehow did *not* happen and the stale table were
used with V1's renamed-but-same-named action functions, behaviour would silently revert
to the *old* (buggy) result rather than crash — so there is no catastrophic-failure
risk, only a (non-occurring) "bug-not-fixed" risk. Regeneration *does* occur, so this is
moot.

## F3. Grammar is LALR-conflict-free — [ok]
Important infrastructure fact: conflicts are only logged when `debug=True`
(`yacc.py:3456`), and `parsing.yacc` passes `debug=False`. So a conflict would be
silently auto-resolved (shift over reduce; first rule for reduce/reduce) and could
change behaviour invisibly. I therefore verified conflict-freeness by FOLLOW-set
analysis rather than relying on warnings:
`FOLLOW(product_of_units) = {$end, ], )}` does **not** contain `DIVISION` or `PRODUCT`,
so in the state after a `unit_expression` the parser unambiguously *shifts* on `.`/`/`
and only *reduces* on end/`]`/`)`; `division_of_units` is right-deterministic
(`{$end,],),DIVISION}` follow). No shift/reduce or reduce/reduce conflict. **Clean.**

## F4. Behavioural regression on the mixed form `a/b.c` (slash-then-dot) — [improve]
This is the main substantive finding. Consider an *un-parenthesized* division whose
denominator is a product, e.g. `mW/m2.s` or generically `a/b.c`.

* **Old (pre-fix) behaviour:** `unit_expression(a) DIVISION combined_units(b.c)` where
  `b.c` reduces (via the product rule) to `b·c`; result `a/(b·c)`. This was *correct*
  and is the only sensible reading. The old bug was confined to `a/b/c` (multiple
  slashes), not to `a/b.c`.
* **V1 behaviour:** V1's division right-operand is a single `unit_expression`, so after
  `a DIVISION b` the trailing `.c` cannot attach: **`a/b.c` now raises `ValueError`
  ("Syntax error")**. Likewise `/a.b` (leading slash, product denominator) now errors.

So V1 fixes `a/b/c` but *regresses* `a/b.c` from a correct parse to a hard error. A real
MRT/CDS file containing `mW/m2.s` (legal-ish, denominator-as-product) would have been
readable before and would now fail to read. The form is non-standard and not covered by
any current test, so this does not fail the visible suite, but **a bug fix should not
turn a previously-parseable input into an error when a clean alternative avoids it.**
V1 thus makes a *larger behavioural change than the bug requires*: it alters both the
broken case (`a/b/c`) and an unrelated, previously-correct case (`a/b.c`).

## F5. The CDS writer / round-trip path is unaffected — [ok]
`CDS.to_string` (`cds.py:311-358`) emits units in **product form with signed integer
powers** (`_format_unit_list` joins with `.` and appends `int(power)`, never `/`), e.g.
`J.m-1.s-1.kpc-2`. Reading that back goes entirely through the *product* rule, which V1
does not change. `TestRoundtripCDS` (single/decomposed units) and the `ascii.mrt`
read/write tests use only simple/product units (`cm.s-2`, `km.s-1`, `m/s`). **No
round-trip regression.** (Confirms the writer needs no change for this issue.)

## F6. No regression in existing CDS grammar tests — [ok]
Walked every case in `test_format.py::test_cds_grammar` (`km/s`, `km.s-1`, `mW/m2`,
`mW/(m2)`, `°/s`, `Å/s`, `[cm/s2]`, factors, single units, dimensionless, etc.) and in
`test_cds_grammar_fail` (`km / s`, `km*s`, `pix/(0.1nm)`, `mag(s-1)`, `[--]`, …). All
pass/fail outcomes are preserved by V1. None of the pass cases exercises a `/`-chain or
`a/b.c`, and none of the fail cases exercises `a/b.c`, which is why F4 is invisible to
the suite.

## F7. Reader integration is correct — [ok]
`Table.read(..., format='ascii.cds'/'ascii.mrt')` resolves unit strings through this CDS
format parser (the issue's own hint reproduces with `u.Unit('10+3J/m/s/kpc2',
format='cds')`). Fixing the format parser fixes the reader; no `io/ascii` change is
needed, and the `io/ascii` test data uses no `/`-chain units, so nothing there
regresses.

## F8. Committed table file left in a deliberately-stale state — [ok / documented]
`_tabversion='0.0'` leaves `cds_parsetab.py` permanently "out of date" until something
rewrites it. On a writable checkout the first parser build regenerates a correct table
(`_tabversion` back to `'3.10'`, new signature/tables); on a read-only checkout every
process rebuilds in memory (one-time per process, correct). A clarifying comment is
present. Hand-writing a correct LALR table is infeasible without execution, and
modifying `parsing.yacc`/`optimize` would affect all four unit formats, so this is the
least-invasive available trigger. **Acceptable; no cleaner option exists under the
no-execution constraint.** Lexer is untouched, so `cds_lextab.py` stays valid.

## F9. Style / convention consistency — [ok]
The change keeps the existing `p_*` docstring-grammar idiom and leaves action bodies
untouched, matching the surrounding code and the sibling OGIP/Generic parsers.

---

## Conclusion / action
V1 is **functionally correct for the reported bug** (F1) and the regeneration mechanism
is sound (F2, F8). The one substantive defect is **F4**: V1 needlessly turns the
previously-correct `a/b.c` (slash-then-product-denominator) into a parse error, i.e. it
changes behaviour beyond the buggy case. The remedy is to restructure the grammar so
that a division's denominator is a *product chain* and divisions chain left-to-right,
which fixes `a/b/c` **and** preserves the old `a/b.c = a/(b·c)` reading — making the
behavioural change minimal (only the genuinely broken multi-slash case changes). See
`reports/control_notes.md` for the implemented change keyed to F4 (and confirmation of
F1-F3, F5-F9).
