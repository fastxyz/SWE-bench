# FVK Proof

Status: constructed, not machine-checked. No tests, Python code, `kompile`, `kast`, or `kprove` were run.

## What Is Proved

For the Python code printer fragment modeled in `mini-python-precedence.k`, the repaired implementation satisfies the modulo precedence obligations in `PROOF_OBLIGATIONS.md`: negative modulo, external multiplier preservation, operand grouping, Python-printer scoping, inherited `_print_Mod` compatibility, and unchanged lambdify selection.

## Symbolic Proof Sketch

### PO-001

Start with `-Mod(x, y)`, represented by a negative multiplication whose remaining factor is `Mod(x, y)`.

`CodePrinter._print_Mul` computes `prec = precedence(expr)`. Because the coefficient is negative, SymPy's `precedence_Mul` returns `PRECEDENCE["Add"]`.

The multiplication printer strips the sign and calls:

```text
parenthesize(Mod(x, y), PRECEDENCE["Add"], strict=False)
```

The Python printer override calls `_precedence(Mod(x, y))`. Exact `Mod` has no `_pythoncode` method and its MRO contains `Mod`, so the result is `PRECEDENCE["Add"]`.

`parenthesize` wraps when `prec <= level` in non-strict mode. Since both sides are `PRECEDENCE["Add"]`, the factor prints as `(x % y)`, and the leading sign gives `-(x % y)`.

Python parses `-(x % y)` as the required negation of the modulo result.

### PO-002

For `c*Mod(x, y)`, positive multiplication uses context level `PRECEDENCE["Mul"]`. The modulo containment precedence is `PRECEDENCE["Add"]`, so `PRECEDENCE["Add"] < PRECEDENCE["Mul"]`; the modulo factor is parenthesized. The generated multiplication therefore contains the whole `%` expression as a factor.

This prevents the bad parse shape `c*x % y`, which would move the multiplier into the modulo dividend.

### PO-003

`_print_Mod` itself was intentionally left using `PREC = precedence(expr)`. For exact `Mod`, generic precedence sees `Function` and returns `PRECEDENCE["Func"]`.

Therefore each operand is printed through:

```text
parenthesize(operand, PRECEDENCE["Func"], strict=False)
```

For an operand such as `y*z`, generic multiplication precedence is lower than function precedence, so the operand becomes `(y*z)`. Thus `Mod(x, y*z)` prints in a way equivalent to `x % (y*z)`, not `(x % y)*z`.

### PO-004

The diff changes only `repo/sympy/printing/pycode.py`. The shared `precedence.py` table and other printers are framed unchanged. Therefore the proof does not rely on a global semantics change.

### PO-005

Printer dispatch uses an expression's class MRO. A subclass of `Mod` without a custom `_pythoncode` method can reach `_print_Mod`; it must therefore share the same containment precedence. V2 checks for `Mod` in the MRO, not just the exact class name.

The `not hasattr(item, self.printmethod)` guard preserves the generic contract for custom `_pythoncode` implementations because such objects do not necessarily emit `%`.

### PO-006

`lambdify.py` is unchanged. When `modules=[]`, the namespace list remains empty and `lambdify` selects `PythonCodePrinter`; the fixed behavior enters through the printer's `parenthesize` method.

## Machine-Check Commands

These commands were not run:

```sh
kompile fvk/mini-python-precedence.k --backend haskell
kast --backend haskell fvk/pycode-mod-precedence-spec.k
kprove fvk/pycode-mod-precedence-spec.k
```

Expected result after running in a K-enabled environment: `#Top` for all claims.

## Residual Risk

This proof is partial correctness over a mini-semantics of the relevant printer fragment, not a full proof of all SymPy printers. It does not prove termination, performance, or all possible custom printmethod contracts.

String formatting is proven at the grouping/parse level, not as a full byte-for-byte grammar for every expression printer. Existing public evidence requires the parse shape, not a unique minimal-parentheses string.

## Test Guidance

Do not remove tests based on this constructed proof. Add or keep tests for:

- `pycode(-Mod(x, y))`
- `lambdify([x, y], -Mod(x, y), modules=[])` source/value behavior
- `pycode(2*Mod(x, y))`
- `pycode(Mod(x, y*z))`
- a `Mod` subclass that inherits `_print_Mod`

Any redundancy recommendation is conditioned on machine-checking the K claims.
