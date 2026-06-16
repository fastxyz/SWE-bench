# FVK Proof Obligations

Status: constructed, not machine-checked. No commands were executed.

## PO-001: Intent adequacy

The formal claims must match public intent rather than V1 behavior alone.

- Discharge argument: `fvk/SPEC.md` I-001 through I-005 are all prompt-derived. FC-001 through FC-003 directly encode builtin `min`/`max` output and absence of unsupported tracking.
- Finding links: F-001, F-002.
- Result: discharged by inspection.

## PO-002: Registration of `Min` and `Max` as known functions

For `PythonCodePrinter`, `Min` and `Max` must be keys in `PythonCodePrinter._kf` with values `min` and `max`.

- Discharge argument: `repo/sympy/printing/pycode.py` now has `_known_functions = {'Abs': 'abs', 'Max': 'max', 'Min': 'min'}`. `AbstractPythonCodePrinter._kf` is built from `_known_functions.items()`.
- Finding links: F-001.
- Result: discharged by inspection.

## PO-003: Method generation for printer dispatch

The known-function keys must create `_print_Min` and `_print_Max` methods on `PythonCodePrinter`.

- Discharge argument: `for k in PythonCodePrinter._kf: setattr(PythonCodePrinter, '_print_%s' % k, _print_known_func)` iterates over the V1-expanded `_kf`.
- Finding links: F-001.
- Result: discharged by inspection.

## PO-004: Dispatch reaches the generated methods

When printing a `Min` or `Max` object, printer dispatch must select `_print_Min` or `_print_Max` before generic fallback.

- Discharge argument: `Printer._print` walks `type(expr).__mro__` and checks `getattr(self, '_print_' + cls.__name__, None)`. Since the generated methods exist on `PythonCodePrinter`, dispatch reaches `_print_known_func`.
- Finding links: F-001.
- Result: discharged by inspection.

## PO-005: Formatting matches the public expected string

The generated methods must emit `min(arg1, arg2, ...)` and `max(arg1, arg2, ...)` with recursively printed arguments.

- Discharge argument: `_print_known_func` retrieves `self.known_functions[expr.__class__.__name__]` and returns `{name}({args})`, where `args` is `', '.join(self._print(arg) for arg in expr.args)`. For unqualified `min` and `max`, `_module_format` returns the same names and registers no module import.
- Finding links: F-001.
- Result: discharged by inspection.

## PO-006: Unsupported marker is not emitted for supported target functions

`Min` and `Max` themselves must not enter `_print_not_supported`.

- Discharge argument: PO-003 and PO-004 route target expressions to `_print_known_func`. `_print_not_supported` is only reached by the generic unsupported path, so the target expression is not added to `_not_supported`.
- Scope note: an unsupported argument inside `Min` or `Max` may still be reported by its own printer path; that is outside this issue and consistent with recursive printing.
- Finding links: F-001.
- Result: discharged by inspection.

## PO-007: Public compatibility and frame conditions

The change must not alter public signatures, user override precedence, or NumPy vectorized `Min`/`Max` behavior.

- Discharge argument: no signature changed. `user_functions` still overrides `_kf` in `AbstractPythonCodePrinter.__init__`. `NumPyPrinter` defines explicit `_print_Min` and `_print_Max`, so its method resolution keeps vectorized behavior. `MpmathPrinter` inherits support, which is compatible for scalar Python/mpmath code.
- Finding links: F-003, F-004.
- Result: discharged by inspection.

## PO-008: Machine-check commands for the formal core

These are the commands that would check the constructed mini-K formalization if execution were allowed:

```sh
cd fvk
kompile mini-pycode.k --backend haskell
kast --backend haskell pycode-printer-spec.k
kprove pycode-printer-spec.k
```

Expected outcome after a successful machine check: `kprove` returns `#Top` for all claims. These commands were not run.
