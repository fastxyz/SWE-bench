# Public Compatibility Audit

Status: constructed, not machine-checked.

Changed public symbol: `sympy.polys.polytools.Poly`.

Changed attribute: `_op_priority` added with value `10.001`.

## Compatibility surface

- Public constructor/signature: unchanged.
- Public return type for already-working `Poly * expr` and Python scalar reverse operations: unchanged.
- Virtual dispatch shape: changed for ordinary `Expr` left operands whose binary operator uses `call_highest_priority`; these operands now delegate to `Poly` reflected arithmetic when `Poly` is on the right.
- Subclasses: `PurePoly` inherits `Poly`, so it inherits the same priority. No separate override conflict was found in the audited source.

## Compatibility decision

The priority value is intentionally just above ordinary `Expr._op_priority == 10.0`. It is not above matrix expression priority (`11.0`) and is below concrete matrix priority (`10.01`), while equal to `ImmutableDenseMatrix`'s existing `10.001` value; equal priority does not force delegation under `call_highest_priority`, which requires strict `>`.

The broader routing is acceptable for this issue because `Poly` already defines reflected add/sub/mul/div/mod/floordiv behavior, and public tests already expect reverse arithmetic for Python scalar operands. The FVK audit found no public callsite or override requiring ordinary expression left operands to keep unevaluated `Add`/`Mul` results when a compatible right-hand `Poly` can handle the operation.

Residual risk: this is not a machine-checked audit over the whole SymPy class hierarchy. Keep public and hidden compatibility tests for mixed `Poly` arithmetic until the emitted K obligations are machine-checked or broader tests are run outside this no-execution benchmark session.
