# Proof Obligations

Status: constructed, not machine-checked.

## PO-DOMAIN

The audited input is a non-empty `MatAdd` argument list. Every term either
supports `as_coeff_mmul()` or is treated as coefficient-positive by fallback.

Evidence: `MatAdd.shape` uses `args[0]`, making empty `MatAdd` out of intended
printer scope; V1 catches `AttributeError` around `as_coeff_mmul()`.

Status: discharged by source inspection.

## PO-SIGN

For each term, the sign classifier used by the printer is:

- coefficient = `term.as_coeff_mmul()[0]` when available;
- coefficient = `S.One` when `as_coeff_mmul()` is not available;
- negative iff `S(coeff).could_extract_minus_sign()`.

If negative, the emitted body is based on `-term`, so a unit negative
coefficient becomes an additive sign rather than body text.

Status: discharged by V1 source inspection in all three changed files.

## PO-NO-PLUS-NEG

An interior negative term must be introduced by a subtraction separator, not by
a plus separator followed by a negative-rendered body.

Status: discharged by `PO-STR`, `PO-LATEX`, and `PO-PRETTY`.

## PO-NO-UNIT-COEFF

A unit negative matrix coefficient must not appear as `(-1)*` in string output
or as `-1` in LaTeX output. Pretty output must not produce a plus sign before a
negative term.

Status: discharged by `PO-SIGN` plus the per-printer obligations.

## PO-STR

Loop invariant for `StrPrinter._print_MatAdd`: after processing any prefix of
`expr.args`, `parts` contains alternating sign/body entries matching
`ExpectedJoin(prefix)`. The first sign is popped, and a leading `+` is erased.
Therefore:

- first positive term has no leading plus;
- first negative term has a leading minus;
- interior positive term has ` + `;
- interior negative term has ` - `;
- body rendering uses `parenthesize` on the positive term body.

Status: constructed proof in `PROOF.md`; represented by `STR-MATADD` and
`JOIN-LOOP`.

## PO-LATEX

Loop invariant for `LatexPrinter._print_MatAdd`: after processing any prefix of
`expr.args`, `tex` equals `ExpectedJoin(prefix)` under LaTeX body rendering.
The first negative term contributes `-` and interior negative terms contribute
` - `. The term body is rendered after replacing the term by `-term`.

Status: constructed proof in `PROOF.md`; represented by `LATEX-MATADD` and
`JOIN-LOOP`.

## PO-PRETTY

Loop invariant for `PrettyPrinter._print_MatAdd`: after processing any prefix
of `expr.args`, `pforms` contains one pretty form per term. Positive terms have
ordinary binding; negative terms are generated from `self._print(-term)` and
wrapped with `prettyForm.NEG` binding using the same sign-prefix rules as the
scalar pretty `Add` printer. `prettyForm.__add__` therefore omits a literal
plus before negative-bound terms.

Status: constructed proof in `PROOF.md`; represented by `PRETTY-MATADD` and
`JOIN-LOOP`.

## PO-FRAME-REP

The fix must not alter `MatAdd`, `MatMul`, `MatrixExpr`, or `MatrixSymbol`
construction or canonicalization.

Status: discharged: V1 edits only printer methods.

## PO-FRAME-ORDER

The fix must not introduce a new ordering rule for matrix-add arguments.

Status: discharged: V1 iterates `expr.args` in existing order in all three
printers.

## PO-FRAME-API

The fix must not change public printer method signatures, dispatch shape, or
return type.

Status: discharged by `PUBLIC_COMPATIBILITY_AUDIT.md`.

## PO-COVERAGE

All matrix-add printer implementations named by the issue must satisfy the sign
join obligation.

Status: discharged: the only `_print_MatAdd` methods under `repo/sympy/printing`
are in `str.py`, `latex.py`, and `pretty/pretty.py`, and all three were updated
in V1.
