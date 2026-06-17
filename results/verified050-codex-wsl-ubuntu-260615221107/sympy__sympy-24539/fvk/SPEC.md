# FVK Spec

Status: constructed, not machine-checked. The K commands are recorded in
`PROOF.md` and were not executed.

## Scope

The audited unit is `PolyElement.as_expr(self, *symbols)` in
`repo/sympy/polys/rings.py`. The compatibility surface includes
`FracElement.as_expr(self, *symbols)` in `repo/sympy/polys/fields.py`, because it
forwards its `symbols` varargs to `PolyElement.as_expr`.

There are no loops or recursive calls in the audited function. The proof
obligations are branch-completeness obligations over the three observable input
classes:

- no replacement symbols supplied;
- replacement symbols supplied with length equal to `self.ring.ngens`;
- replacement symbols supplied with any other length.

## Public Intent Ledger

Critical public evidence is mirrored from `PUBLIC_EVIDENCE_LEDGER.md`:

- E-1/E-2: the issue says `PolyElement.as_expr` is supposed to let callers set
  the symbols they want to use.
- E-3: the issue's `U, V, W` example identifies use of `self.ring.symbols` on a
  same-arity supplied-symbol call as the defect.
- E-4: wrong arity remains an error.
- E-5/E-6: visible public tests support default conversion and same-arity
  positional conversion, but do not distinguish distinct replacement symbols.
- E-7: `expr_from_dict` uses the provided generator tuple positionally.
- E-8: `FracElement.as_expr` depends on `PolyElement.as_expr` forwarding
  behavior.

## Contract

Let `P` be a `PolyElement`, `D = P.as_expr_dict()`, and
`R = P.ring`.

1. If `symbols` is empty, `P.as_expr()` returns
   `expr_from_dict(D, *R.symbols)`.
2. If `symbols` is non-empty and `len(symbols) == R.ngens`,
   `P.as_expr(*symbols)` returns `expr_from_dict(D, *symbols)`.
3. If `symbols` is non-empty and `len(symbols) != R.ngens`,
   `P.as_expr(*symbols)` raises `ValueError` before expression conversion.
4. The method signature and positional calling convention remain unchanged.
5. `FracElement.as_expr(*symbols)` continues to forward the same `symbols` to
   numerator and denominator conversion.

## Formal Core

The formal core is in:

- `mini-python.k`: a reduced mini-semantics for the branch behavior relevant to
  `as_expr`.
- `poly-element-as-expr-spec.k`: K claims for default conversion, supplied-symbol
  conversion, wrong-arity rejection, and fraction forwarding.

The mini-semantics keeps the property under audit observable: the `Symbols`
argument passed to `exprFromDict` is part of the result term. A failing
implementation that overwrites supplied symbols with `ringSymbols(P)` maps to a
different result than the repaired implementation.
