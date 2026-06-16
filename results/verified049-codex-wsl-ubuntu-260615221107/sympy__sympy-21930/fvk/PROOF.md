# FVK Proof

Status: constructed, not machine-checked. No commands were executed.

## Claims Proved Constructively

C1 / PO1. Standard powers of secondquant creation operators print as a grouped
creator base followed by the outer exponent.

C2 / PO2. Folded fractional powers of secondquant creation operators print as a
grouped creator base followed by the folded exponent.

C3 / PO4. Direct creator printing remains unchanged.

C4 / PO5. Non-creator power printing remains on legacy paths.

C5 / PO6. Public compatibility is preserved.

## Proof Sketch

### Standard Power Path

Let `C` be an instance of a `Creator` subclass, and let direct printing of `C`
produce the string `L`.

1. `LatexPrinter._helper_print_standard_power` computes
   `custom_base = getattr(expr.base, '_latex_power_base', None)`.
2. Because `C` inherits `Creator._latex_power_base`, `custom_base is not None`.
3. The helper sets `base = custom_base(self)`.
4. `Creator._latex_power_base` returns `{%s}` with `%s` replaced by
   `printer._print(self)`, so `base = {L}`.
5. The symbol-specific `parenthesize_super` branch is skipped because it is
   guarded by `custom_base is None`.
6. The helper returns the standard template `%s^{%s}`, so the result is
   `{L}^{E}`.

For `L = b^\dagger_{0}` and `E = 2`, this is
`{b^\dagger_{0}}^{2}`, which discharges the public issue example.

### Folded Fractional Power Path

Let `C` be an instance of a `Creator` subclass, direct printing produce `L`, and
the folded exponent be `P/Q`.

1. `LatexPrinter._print_Pow` reaches the folded fractional-power branch.
2. It computes `custom_base = getattr(expr.base, '_latex_power_base', None)`.
3. Because `C` inherits the hook, `base = custom_base(self) = {L}`.
4. The symbol-specific protection and function-specific exponent fallback are
   both guarded by `custom_base is None`, so they do not override the hook.
5. The branch returns `%s^{%s/%s}`, so the result is `{L}^{P/Q}`.

This discharges the proof-derived consistency finding F2.

### Direct Creator Printing Frame

Direct printing of `Bd(i)` or `Fd(p)` dispatches to the object's `_latex`
implementation. `CreateBoson._latex` and `CreateFermion._latex` were not edited.
The new `_latex_power_base` method is not called unless the generic power printer
looks it up from a power base. Therefore direct output remains
`b^\dagger_{i}` and `a^\dagger_{p}`.

### Non-Creator Frame

For an expression base without `_latex_power_base`,
`getattr(..., '_latex_power_base', None)` returns `None`.

In that case, both modified branches execute the previous `parenthesize` logic,
and all existing symbol/function/derivative branches remain available under the
same public conditions. Thus the patch does not change unrelated power printing.

### Compatibility

No existing public method signature was changed. The new hook is an optional
private method and only affects objects that opt into it by defining or
inheriting it. In-tree `Creator` subclasses share the same daggered
superscripted base shape, so the shared hook is appropriate.

## K-Style Artifact Commands

These commands are emitted for later machine checking and were not run:

```sh
kompile fvk/mini-python-latex.k --backend haskell
kast --backend haskell fvk/secondquant-latex-spec.k
kprove fvk/secondquant-latex-spec.k
```

Expected result if the constructed mini semantics and claims are accepted by the
toolchain: `kprove` returns `#Top` for the string-output claims corresponding to
PO1, PO2, PO4, and PO5. PO3 follows from PO1 and PO2; PO6 is discharged by the
source compatibility audit.

## Residual Risk

The proof is partial correctness over the modeled printer branches; termination
and full real-Python semantics are not proved. The K artifacts are a minimal
domain-specific fragment, not the full SymPy printer. Test removal is not
recommended because this task forbids test edits and the proof was not
machine-checked.
