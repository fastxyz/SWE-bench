# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`, or `kprove` were run.

## What Is Proved

For every plain `PythonCodePrinter` invocation over a `Min` or `Max` expression whose arguments are printable by the same printer, the target expression is printed as a Python builtin call:

- `Min(args...)` prints as `min(printed_args...)`.
- `Max(args...)` prints as `max(printed_args...)`.
- The target `Min` or `Max` expression is not recorded in `_not_supported`.

This is a partial-correctness proof of the printer dispatch and formatting path. Termination is inherited from finite `expr.args` traversal and is not machine-proved here.

## Proof Sketch

1. By PO-001, the intended behavior is the public issue behavior: support `Min` and `Max` in `PythonCodePrinter` as Python builtin `min` and `max`.
2. By PO-002, V1 places `Max: max` and `Min: min` in `_known_functions`, and `PythonCodePrinter._kf` is built from that table.
3. By PO-003, class initialization code creates `_print_Max` and `_print_Min` methods on `PythonCodePrinter`, each bound to `_print_known_func`.
4. By PO-004, printer dispatch checks `_print_<class name>` methods along the expression class MRO, so `Min` reaches `_print_Min` and `Max` reaches `_print_Max`.
5. By PO-005, `_print_known_func` formats the known function name and recursively printed arguments as `{name}({args})`; with V1's table entries this yields `min(...)` and `max(...)`.
6. By PO-006, because dispatch reaches `_print_known_func`, the target expression does not reach `_print_not_supported` and therefore does not produce the issue's unsupported-function preamble.
7. By PO-007, no public signature or override contract is broken, and NumPy keeps its explicit vectorized methods.

## Formal Core

The mini semantics in `fvk/mini-pycode.k` models the relevant printer fragment: known function lookup, recursive argument printing, comma joining, and unsupported tracking. The claims in `fvk/pycode-printer-spec.k` cover `Min`, variadic `Max`, and nested recursive printing.

Machine-check commands, not executed:

```sh
cd fvk
kompile mini-pycode.k --backend haskell
kast --backend haskell pycode-printer-spec.k
kprove pycode-printer-spec.k
```

Expected machine result if the constructed claims and mini semantics are accepted: `#Top`.

## Test Guidance

No tests were modified. Existing public tests cover NumPy `Min`/`Max` behavior but not plain `pycode` output. After machine-checking, focused plain-printer point tests such as `pycode(Min(x, y)) == "min(x, y)"` and `pycode(Max(x, y, z)) == "max(x, y, z)"` would be subsumed by FC-001 and FC-002, but keeping them is still useful as integration/regression coverage until the K proof is actually machine-checked.

## Residual Risk

- The proof is constructed, not machine-checked.
- The mini semantics is intentionally narrower than real SymPy/Python; it models only the dispatch and formatting behavior relevant to this issue.
- Runtime semantics of Python's `min` and `max` on arbitrary user objects are outside the code-printer string contract.
