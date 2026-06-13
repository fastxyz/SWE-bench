# Control notes — V2 of the fix for astropy__astropy-14369

This document explains every decision made during the review/revision pass, keyed to the
numbered findings in `review/FINDINGS.md`.

## Summary of what changed vs. V1
V1 changed only `p_division_of_units` to make division left-recursive with single
`unit_expression` operands. The review (F4) found that, although V1 fixes the reported
`a/b/c` bug, it *also* breaks an unrelated, previously-correct case: an un-parenthesized
division with a product denominator such as `a/b.c` (`mW/m2.s`) used to parse as
`a/(b·c)` but raises `ValueError` under V1.

V2 keeps the same overall approach (left-recursive division + table regeneration) but
restructures the grammar so the change to observable behaviour is *minimal* — only the
genuinely broken multi-slash case changes.

### Code change (`astropy/units/format/cds.py`)
Two productions changed; **both action bodies are unchanged**:

```
product_of_units : unit_expression PRODUCT product_of_units      # was: ... PRODUCT combined_units
                 | unit_expression

division_of_units : DIVISION product_of_units                    # was: DIVISION unit_expression
                  | product_of_units DIVISION product_of_units    # was: unit_expression DIVISION unit_expression
                  | division_of_units DIVISION product_of_units   # was: division_of_units DIVISION unit_expression
```

Rationale:
* Making the product chain recurse on `product_of_units` (not `combined_units`) means a
  product chain can no longer contain a top-level division, so when a division's
  operands are `product_of_units` they denote exactly *a product of units*.
* Division is left-recursive (`division_of_units DIVISION product_of_units`), so a `/`
  chain accumulates entirely into the denominator: `a/b/c → ((a/b)/c) = a/(b·c)`.
* Because each denominator is a full `product_of_units`, `a/b.c` parses as
  `a / (b·c)` — the *old, correct* reading — instead of erroring.

### No change (`astropy/units/format/cds_parsetab.py`)
`_tabversion='0.0'` (and its explanatory comment) is retained unchanged.

## Decision-by-decision, traced to findings

1. **Decision: revise V1 rather than confirm it.**
   Justified by **F4** (the only `[improve]`/`[blocking]`-class finding). F1-F3, F5-F9
   were all `[ok]`, so the revision is targeted solely at F4. A bug fix should not
   convert a previously-parseable, correctly-handled input (`a/b.c`) into an error.

2. **Decision: fix F4 by making a division's denominator a `product_of_units`
   (product chain) and chaining divisions left-recursively, rather than V1's
   single-`unit_expression` operands.**
   Directly addresses **F4**. Behavioural comparison for the inputs that distinguish the
   options (✓ = parses to the value shown):

   | input        | old (buggy)        | V1                  | V2 (this change)    |
   |--------------|--------------------|---------------------|---------------------|
   | `J/m/s/kpc2` | `J·s/(m·kpc2)` ✗    | `J/(m·s·kpc2)` ✓     | `J/(m·s·kpc2)` ✓     |
   | `a/b/c`      | `a·c/b` ✗          | `a/(b·c)` ✓          | `a/(b·c)` ✓          |
   | `a/b.c`      | `a/(b·c)` ✓        | **ValueError** ✗     | `a/(b·c)` ✓          |
   | `a.b/c`      | `a·b/c` ✓          | `a·b/c` ✓            | `a·b/c` ✓            |

   V2 changes observable behaviour **only** for the genuinely broken multi-slash case,
   leaving the previously-correct `a/b.c` untouched. This makes V2 the minimal
   behavioural change consistent with fixing the issue.

3. **Decision: keep the bug fix itself (left-to-right `/` chaining).**
   Confirms **F1**. Re-traced end-to-end on the issue's own inputs: `10+3J/m/s/kpc2 →
   1000 J / (kpc2 m s)` and `10-7J/s/kpc2 → 1e-7 J / (kpc2 s)`, matching the issue's
   "expected" output exactly.

4. **Decision: rely on the unchanged action bodies (`p[2]**-1`, `p[1]/p[3]`,
   `p[1]*p[3]`).**
   Consistent with **F1** and **F9**: under the new left-recursive rules `p[1]` is the
   accumulated left operand, so the original arithmetic is still correct, and keeping the
   bodies identical minimizes risk and preserves the codebase's `p_*` idiom.

5. **Decision: re-verify LALR conflict-freeness for the *new* grammar by analysis.**
   Driven by **F3** (conflicts are silently auto-resolved because `parsing.yacc` runs
   with `debug=False`, so I cannot rely on warnings). For V2:
   `FOLLOW(product_of_units) = {$end, ], ), DIVISION}` and
   `FOLLOW(division_of_units) = {$end, ], ), DIVISION}`; neither contains `PRODUCT`, so
   after a `unit_expression` the parser *shifts* on `.` (rule p2) and *reduces* p1 only
   on `/`,`]`,`)`,`$end`; after a `product_of_units` it *shifts* on `/` (rule d2) and
   reduces to `combined_units` only on `]`,`)`,`$end`; `division_of_units` shifts on `/`
   (rule d3) and reduces to `combined_units` otherwise. No shift/reduce or reduce/reduce
   conflict. (The denominator `product_of_units` in d2/d3 cannot itself start a new
   division, because closure of `… DIVISION . product_of_units` adds only
   `product_of_units` productions, not `division_of_units : . product_of_units …`.)

6. **Decision: keep `_tabversion='0.0'` to force table regeneration.**
   Justified by **F2** and **F8**. The grammar still changed, so the cached table is
   still stale and `optimize=True` would still reuse it; the `VersionError`-triggered
   rebuild path is unchanged and will now regenerate V2's grammar. No cleaner trigger is
   available without an execution environment, and the lexer is still untouched
   (`cds_lextab.py` valid). The existing explanatory comment remains accurate.

7. **Decision: do not touch `CDS.to_string` / the writer.**
   Justified by **F5**: the writer emits product form with signed integer powers
   (`J.m-1.s-1.kpc-2`), never `/` chains, so round-trips and `ascii.mrt` write tests read
   back through the (still-correct) product rule. The issue is read-only; the writer is
   not implicated.

8. **Decision: do not modify any `io/ascii` reader code or test data.**
   Justified by **F7**: the reader resolves units through this format parser, so fixing
   the parser fixes the reader; existing CDS/MRT test data contains no `/`-chain units
   and so does not regress.

9. **Decision: confirm no regression in the visible CDS test suite.**
   Justified by **F6**: re-walked every `test_cds_grammar` pass case and
   `test_cds_grammar_fail` case against the V2 grammar. All pass/fail outcomes are
   preserved (e.g. `km/s`, `km.s-1`, `mW/m2`, `mW/(m2)`, `°/s`, `[cm/s2]` still parse;
   `km / s`, `km*s`, `pix/(0.1nm)`, `mag(s-1)`, `[--]` still fail). V2 additionally
   accepts the non-standard `a/b.c` and `/a.b` (denominator-as-product) forms, none of
   which appears in the fail list, so nothing that should fail now passes.

## Net effect
The reported bug is fixed (F1/F3), the V1 regression on `a/b.c` is removed (F4), and all
other reviewed properties (F2, F5-F9) are preserved. The observable behavioural change
relative to *pre-fix* astropy is now confined to the multi-slash `/`-chain case that the
issue reported.
