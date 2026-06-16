# PROOF

Constructed, not machine-checked. No K tooling was executed.

## Claims Proved In The Constructed Model

- MC-MAX: dispatching a `MaxClass` expression named `"Max"` reaches
  `bracketCall("Max", ARGS)`.
- MC-MIN: dispatching a `MinClass` expression named `"Min"` reaches
  `bracketCall("Min", ARGS)`.
- MC-FUNCTION-FRAME: ordinary function dispatch remains bracket-call based.
- MC-EXPR-FALLBACK-FRAME: unsupported generic expression fallback remains
  parenthesis/repr based.

## Source-Level Proof Sketch

`Printer._print` checks for a printer method named `_print_<ClassName>` by
walking the expression class MRO. For `Max`, V1 supplies `_print_Max`; for `Min`,
V1 supplies `_print_Min`. These methods are found before inherited `_print_Expr`,
so the old unsupported path is bypassed for exactly those classes.

Both V1 methods return `self._print_Function(expr)`. In `MCodePrinter`,
`_print_Function` emits either a known/user mapped Mathematica name or the
expression's function name followed by square brackets around
`self.stringify(expr.args, ", ")`. Therefore the observable output shape for
`Max` and `Min` is bracket-call syntax.

Because V1 does not modify `_print_Function`, ordinary functions keep their
existing bracket-call behavior. Because V1 does not override `_print_Expr` or
`emptyPrinter`, unsupported generic expressions keep their old fallback behavior.

## K-Style Symbolic Execution

The mini semantics in `mini-python-printer.k` has no loops or recursion, so no
circularity is needed.

For MC-MAX:

1. Initial state:
   `<k> dispatch(expr(MaxClass, "Max", ARGS)) </k><out> "" </out>`.
2. Dispatch rule for `MaxClass` rewrites the k cell to
   `printFunction(expr(MaxClass, "Max", ARGS))`.
3. `printFunction` rewrites to `emit(bracketCall("Max", ARGS))`.
4. `emit` rewrites the k cell to `.K` and the output cell to
   `bracketCall("Max", ARGS)`.

MC-MIN is identical with `"Min"`. MC-FUNCTION-FRAME uses the ordinary
`FunctionClass` dispatch rule, also reaching `printFunction`. MC-EXPR-FALLBACK
uses the `ExprClass` dispatch rule, reaching `unsupportedFallback` and then
`parenCall`.

## Verification Conditions

There are no arithmetic VCs and no loop side conditions. The relevant VCs are
dispatch exclusivity/frame conditions:

- `MaxClass` and `MinClass` have class-specific printer rules in V1.
- `FunctionClass` still maps to `printFunction`.
- `ExprClass` still maps to `unsupportedFallback`.
- The output cell after `emit(S)` equals `S`.

All are discharged by direct symbolic rewriting in the constructed model.

## Machine-Check Commands

These commands are required for a future machine check, but were not run here:

```sh
cd fvk
kompile mini-python-printer.k --backend haskell
kast --backend haskell mathematica-printer-spec.k
kprove mathematica-printer-spec.k
```

Expected result if the constructed claims are accepted by K: `#Top`.

## Test Guidance

No tests were modified. Existing public tests for ordinary Mathematica function
printing should be kept. New tests that would be subsumed after machine-checking
include:

- `mathematica_code(Max(x, 2)) == "Max[2, x]"`
- `mathematica_code(Min(x, 2)) == "Min[2, x]"`

Any test-removal recommendation is conditional on actually running `kprove` and
obtaining `#Top`; until then, keep tests.

## Residual Risk

The proof is constructed, not machine-checked. The trusted base is the adequacy
of the mini dispatch semantics for the bracket-vs-parenthesis observable, the
source inspection connecting that mini model to `MCodePrinter`, and the future K
toolchain run. Termination is trivial in the mini model because the dispatch
fragment is straight-line.
