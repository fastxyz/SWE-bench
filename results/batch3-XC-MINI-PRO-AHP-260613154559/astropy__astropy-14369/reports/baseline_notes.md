# Baseline notes — astropy__astropy-14369

## Issue
Reading MRT/CDS tables (`format='ascii.cds'`) parses composite units with multiple
slashes incorrectly. The denominator order is "jumbled":

* `10+3J/m/s/kpc2` parsed as `1e+3 J s / (kpc2 m)`  (the `s` is in the wrong place)
* `10-7J/s/kpc2`   parsed as `1e-7 J kpc2 / s`       (`kpc2` is in the wrong place)

Expected (per the CDS standard, where `/` chains build a single denominator):

* `10+3J/m/s/kpc2` → `1000 J / (kpc2 m s)`
* `10-7J/s/kpc2`   → `1e-7 J / (kpc2 s)`

The bug is in the CDS unit-format parser, not in `astropy.units` proper — the generic
parser (`u.Unit('10+3J/m/s/kpc2')`) already returns the correct unit, while
`u.Unit('10+3J/m/s/kpc2', format='cds')` returns the wrong one.

## Root cause
`astropy/units/format/cds.py` builds a PLY/yacc grammar. Division was defined
**right-recursively**:

```
division_of_units : DIVISION unit_expression
                  | unit_expression DIVISION combined_units   # <-- right operand is a full expression
```

Because the right operand is `combined_units` (which can itself be another division),
a chain `a/b/c/d` is grouped right-associatively as `a/(b/(c/d))`. Division is **not**
associative, so the grouping changes the result:

```
J/m/s/kpc2  ->  J / (m / (s / kpc2))  =  J·s / (m·kpc2)      # wrong (what astropy produced)
```

whereas the intended (and standard) meaning is left-associative — each successive
`/unit` adds that unit to the denominator:

```
J/m/s/kpc2  ->  ((J/m)/s)/kpc2        =  J / (m·s·kpc2)      # correct
```

A second, infrastructural factor matters for the fix to take effect: the parser tables
are pre-generated into `cds_parsetab.py` and loaded by PLY with `optimize=True`
(see `astropy/utils/parsing.py::yacc` → `astropy/extern/ply/yacc.py:3294`,
`if optimize or (read_signature == signature)`). With `optimize=True`, PLY reuses the
cached table **verbatim** and never checks the grammar signature, so editing the
grammar in `cds.py` alone has no effect — the stale cached table keeps being used.

## Files changed

### 1. `astropy/units/format/cds.py` — `p_division_of_units`
Changed the grammar to make division left-associative (left-recursive):

```
division_of_units : DIVISION unit_expression
                  | unit_expression DIVISION unit_expression
                  | division_of_units DIVISION unit_expression
```

The Python action body is **unchanged**:
* leading-slash form `DIVISION unit_expression` (`len(p) == 3`) → `p[0] = p[2] ** -1`
* both binary forms (`len(p) == 4`) → `p[0] = p[1] / p[3]`

With left recursion, `p[1]` is the accumulated left-hand result, so
`division_of_units DIVISION unit_expression` evaluates `(…)/next`, i.e. left-to-right.
Now `J/m/s/kpc2` reduces as `((J/m)/s)/kpc2 = J/(m·s·kpc2)`.

The `product_of_units` rule was deliberately left untouched: multiplication is
commutative, so its existing right-recursion is harmless, and the reported bug is
purely about division order. Keeping the change minimal reduces risk.

### 2. `astropy/units/format/cds_parsetab.py` — force regeneration
Set `_tabversion = '0.0'` (was `'3.10'`) with an explanatory comment. PLY's
`LRTable.read_table` raises `VersionError` when the stored `_tabversion` differs from
`__tabversion__` (`'3.10'`); `yacc()` catches that exception
(`astropy/extern/ply/yacc.py:3302`) and rebuilds the parser from the current grammar,
rewriting the table file when the directory is writable
(`write_table`, line 3484; an `IOError` there is caught at line 3487 and the in-memory
parser is used). This is the in-place equivalent of the documented regeneration
workflow ("remove the file … then build and run the tests"), which is required here
because `optimize=True` otherwise bypasses the grammar-signature check and would keep
using the old, right-recursive table.

The file is consumed only by PLY (verified by search; `pyproject.toml` merely excludes
`*_parsetab.py` from linting), so invalidating it has no other side effects. The lexer
is unchanged (same token set), so `cds_lextab.py` is left as-is.

## Verification (by hand, no execution available)
Tracing the fixed grammar:
* `10+3J/m/s/kpc2` → factor `10**3 = 1000`; `J/m/s/kpc2` → `((J/m)/s)/kpc2` →
  `1000 · J/(m·s·kpc2)` = `1000 J / (kpc2 m s)`. ✓
* `10-7J/s/kpc2` → `1e-7 · J/(s·kpc2)` = `1e-7 J / (kpc2 s)`. ✓

Existing CDS behaviour preserved (no `/`-chains): `km/s`, `km.s-1`, `mW/m2`,
`mW/(m2)`, `°/s`, `Å/s`, `[cm/s2]`, `m2`, `10pix/nm`, `1.5x10+11m`, etc. all parse as
before. The `test_cds_grammar_fail` cases still fail. The CDS writer (`to_string`)
emits product form with signed integer powers (e.g. `J.m-1.s-1.kpc-2`), never `/`
chains, so the round-trip tests (`TestRoundtripCDS`) and the `io/ascii` MRT
read/write tests (which use only simple/product units such as `cm.s-2`, `km.s-1`,
`m/s`) parse through the unchanged product rule and are unaffected.

I also verified by FOLLOW-set analysis that the new grammar is LALR conflict-free:
neither `DIVISION` nor `PRODUCT` is in `FOLLOW(product_of_units)`, so the state reached
after a `unit_expression` shifts unambiguously (no shift/reduce conflict), and the
left-recursive `division_of_units` chain reduces deterministically.

## Assumptions and alternatives considered (and rejected)

* **Left-associative vs. "denominator mode".** For pure division chains (the reported
  cases) both interpretations agree: `X/y1/.../yn = X/(y1·…·yn)`. They differ only for
  mixed, un-parenthesized `/`-then-`.` strings. I chose **left-associative** because it
  matches the sibling OGIP parser in this same package
  (`erg /pixel /s /GHz == erg/(pixel·s·GHz)`, implemented with left-recursive rules) and
  is the conventional reading of `/` and `·` as equal-precedence, left-associative
  operators.

* **Fixing it in the action code instead of the grammar.** Rejected: associativity is
  structural (it is the shape of the parse tree). By the time an action runs, the right
  operand has already been collapsed into a single `Unit`, so the action cannot tell
  whether it came from a product or a division and cannot recover the correct grouping.

* **Minimal change vs. full left-recursive restructure.** I changed only the division
  rule. A side effect is that an un-parenthesized division-then-product such as `a/b.c`
  (no parentheses) now raises a parse error instead of the previous `a/(b·c)`;
  parenthesized `a/(b.c)` still works. This form is not part of CDS/MRT practice
  (negative exponents or parentheses are used), is not produced by the writer, and is
  not exercised by any test. Making both product and division fully left-recursive
  (OGIP style) would instead parse `a/b.c` as `(a/b)·c`; I rejected that as a larger,
  riskier change with no benefit to the reported issue.

* **Hand-writing a corrected `cds_parsetab.py`.** Rejected as infeasible/error-prone
  (it is a generated LALR state table); forcing PLY to regenerate from the grammar is
  the supported mechanism.
