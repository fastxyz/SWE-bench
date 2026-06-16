# FVK Proof

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were executed.

## Summary

The V1 source change satisfies the intent spec for supported `Indexed`
expressions:

- `Indexed` now dispatches to `PythonCodePrinter._print_Indexed`.
- `Idx` now dispatches to `PythonCodePrinter._print_Idx`.
- The generated code body is native Python subscript syntax.
- The supported `Indexed` and `Idx` objects are not recorded in
  `_not_supported`, so `CodePrinter.doprint` has no unsupported preamble to emit
  for the reported case.

There are no loops or recursive calls in the changed code, so there are no loop
circularities.

## PO-001: Indexed subscript rendering

Source under proof:

```python
def _print_Indexed(self, expr):
    base = expr.base.label if hasattr(expr.base, 'label') else expr.base
    inds = [self._print(i) for i in expr.indices]
    return "%s[%s]" % (self._print(base), ", ".join(inds))
```

Constructed derivation for `IndexedBase("p")[0]`:

1. `expr.base` is an `IndexedBase`.
2. `IndexedBase` has `label`, so `base = expr.base.label`.
3. The label is the symbol `p`.
4. `self._print(base)` renders `p` through the existing symbol printer.
5. `expr.indices` is the one-element tuple `(0,)`.
6. The list comprehension renders the index as `0`.
7. Joining one rendered index gives `0`.
8. The format expression returns `p[0]`.

This proves the reported output body.

## PO-002: Idx label rendering

Source under proof:

```python
def _print_Idx(self, expr):
    return self._print(expr.label)
```

Constructed derivation for `IndexedBase("A")[Idx("i")]`:

1. `_print_Indexed` recursively calls `self._print(i)` for the index.
2. Printer dispatch sees the runtime class `Idx`.
3. Because V1 defines `_print_Idx`, dispatch selects it before the generic
   `Expr` printer.
4. `_print_Idx` renders `expr.label`.
5. `Idx("i").label` is the symbol `i`, so the result is `i`.
6. `_print_Indexed` formats the result as `A[i]`.

This closes the dependent case that would remain unsupported if only
`_print_Indexed` existed.

## PO-003: Index order and separator

For `IndexedBase("A")[i, j]`:

1. `expr.indices` is `(i, j)` in construction order.
2. The list comprehension iterates over `expr.indices` without sorting or
   filtering.
3. The rendered list is `["i", "j"]`.
4. `", ".join(inds)` gives `i, j`.
5. The result is `A[i, j]`.

No implementation branch can reverse, flatten, or omit the indices because the
method has no such branch.

## PO-004: Unsupported-set preservation

Relevant source facts:

- `Printer._print` tries `_print_<ClassName>` methods along the class MRO before
  falling back.
- `CodePrinter._print_Expr` routes unsupported expressions through
  `_print_not_supported`.
- `CodePrinter.doprint` emits the "Not supported in Python" preamble only from
  `_not_supported`.

Constructed derivation:

1. For an `Indexed` input, dispatch now finds `_print_Indexed` on
   `PythonCodePrinter`.
2. Because a class-specific method is found, dispatch does not reach
   `CodePrinter._print_Expr` for that `Indexed` object.
3. `_print_Indexed` does not call `_print_not_supported`.
4. For an `Idx` index, dispatch now finds `_print_Idx`.
5. `_print_Idx` does not call `_print_not_supported`.
6. Therefore neither the supported `Indexed` object nor the supported `Idx`
   index is inserted into `_not_supported`.
7. Therefore `doprint` has no unsupported preamble to emit for
   `pycode(IndexedBase("p")[0])` or `pycode(IndexedBase("A")[Idx("i")])`.

Nested subexpressions outside the printable Python domain remain governed by
existing recursive printer behavior. That is a frame condition, not a regression.

## PO-005: Compatibility and inheritance

Constructed compatibility proof:

1. V1 adds methods but changes no existing method signature.
2. The public wrapper `pycode(expr, **settings)` still constructs
   `PythonCodePrinter(settings).doprint(expr)`.
3. `LambdaPrinter` subclasses `PythonCodePrinter`, so the lambdify-oriented
   printer inherits the new behavior without caller changes.
4. `TensorflowPrinter` subclasses `AbstractPythonCodePrinter`, so V1 does not
   accidentally alter TensorFlow-specific printing.
5. Other language printers define their own `_print_Indexed` methods and are
   untouched.

Compatibility proof status: pass.

## Machine Check Commands

These commands are emitted for a future environment with K installed. They were
not run here.

```sh
kompile fvk/mini-python-printer.k --backend haskell
kast --backend haskell fvk/pycode-indexed-spec.k
kprove fvk/pycode-indexed-spec.k
```

Expected result in a K-enabled environment: `kprove` discharges the claims to
`#Top`.

## Test Recommendation

No test files were modified.

No existing public test was identified as redundant solely from this constructed
proof. Recommended additions, not applied here:

- `pycode(IndexedBase("p")[0]) == "p[0]"`.
- `pycode(IndexedBase("A")[i, j]) == "A[i, j]"`.
- `pycode(IndexedBase("A")[Idx("i")]) == "A[i]"`.
- `pycode(IndexedBase("p")[0], human=False)` has an empty unsupported set.
- `lambdarepr(IndexedBase("p")[0]) == "p[0]"`.

Any future test-removal decision is conditioned on machine-checking the claims.

## Residual Risk

- The proof is constructed, not machine-checked.
- The K fragment is intentionally smaller than real Python and real SymPy.
- Termination is not a concern for the changed methods because the code is
  straight-line apart from recursive calls into the existing printer for finite
  subexpressions.
