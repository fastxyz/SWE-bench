# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent,
source inspection, and proof construction only.

## F-1: Supplied symbols were overwritten before expression construction

- Classification: code bug, resolved by V1.
- Evidence: ledger E-1, E-2, and E-3.
- Input: `f.as_expr(U, V, W)` for a three-generator polynomial with ring
  symbols `x, y, z`.
- Pre-V1 observed behavior: `expr_from_dict` received `self.ring.symbols`, so
  the expression used `x, y, z`.
- Expected behavior: `expr_from_dict` receives the supplied tuple
  `(U, V, W)`, so the expression uses `U, V, W`.
- V1 status: resolved. `PolyElement.as_expr` now assigns `self.ring.symbols`
  only on the empty-varargs branch; the same-arity branch preserves `symbols`.
- Related proof obligations: PO-2 and PO-4.

## F-2: Existing public tests did not distinguish same-named replacement symbols

- Classification: test gap, not a source-code blocker.
- Evidence: ledger E-6.
- Input shape: `f.as_expr(U, V, W)` with names different from the ring symbols.
- Observed public-test limitation: visible tests pass `symbols("x,y,z")`, which
  can match the same printed expression whether the implementation uses the
  supplied tuple or `self.ring.symbols`.
- Expected coverage: at least one public test should use distinct symbols such
  as `u, v, w` for `PolyElement.as_expr`; a matching forwarding test for
  `FracElement.as_expr` would cover the compatibility path.
- V1 status: no code change required. This is coverage guidance only, and the
  task forbids modifying tests.
- Related proof obligations: PO-2 and PO-5.

## F-3: Wrong-arity error wording is outside the audited intent

- Classification: underspecified intent / non-blocking compatibility note.
- Evidence: ledger E-4.
- Input shape: too few or too many supplied symbols.
- Observed behavior: wrong arity raises `ValueError`; the existing message says
  "not enough symbols" even for too many symbols.
- Expected behavior from public intent: an error on wrong arity. The issue does
  not require a more precise message.
- V1 status: no code change. Keeping the existing message avoids broadening the
  public surface beyond the issue.
- Related proof obligation: PO-3.

## Proof-derived findings from `/verify`

No proof-derived code bug was found after formalizing all three
`PolyElement.as_expr` branch classes. The constructed proof obligations cover
the full intended behavior space for this issue: default conversion,
same-arity supplied-symbol conversion, wrong-arity rejection, and fraction-field
forwarding. The proof remains constructed, not machine-checked.
