# FVK Spec: sympy__sympy-22914

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Scope

The audited observable is plain Python code generation for SymPy `Min` and `Max` through `PythonCodePrinter.doprint` and `pycode`. The verified domain is `Min` and `Max` expressions whose arguments are themselves printable by the same printer. Runtime ordering semantics of Python's `min` and `max` are outside this printer-string contract.

## Intent Spec

- I-001: Source `benchmark/PROBLEM.md`: "PythonCodePrinter doesn't support Min and Max". Obligation: `PythonCodePrinter` must recognize `Min` and `Max` as supported functions.
- I-002: Source `benchmark/PROBLEM.md`: the shown `pycode(Min(a,b))` output has an unsupported-function comment and `Min(a, b)`. Obligation: that unsupported marker is the defect, not behavior to preserve.
- I-003: Source `benchmark/PROBLEM.md`: suggested `_print_Min` returns `"min({})"` over `expr.args`. Obligation: `Min` prints as Python builtin `min` with all recursively printed arguments joined by `", "`.
- I-004: Source `benchmark/PROBLEM.md`: suggested `_print_Max` returns `"max({})"` over `expr.args`. Obligation: `Max` prints as Python builtin `max` with all recursively printed arguments joined by `", "`.
- I-005: Source public hint: adding `Min` to `_known_functions` leads to `PythonCodePrinter().doprint(Min(x,y)) == 'min(x, y)'`. Obligation: using the known-function table is an acceptable implementation path.

## Implementation Facts

- C-001: `repo/sympy/printing/pycode.py` defines `_known_functions` and `AbstractPythonCodePrinter._kf` from that table plus math functions.
- C-002: `repo/sympy/printing/pycode.py` registers `_print_<name>` methods for every key in `PythonCodePrinter._kf` using `_print_known_func`.
- C-003: `_print_known_func` looks up `expr.__class__.__name__` in `self.known_functions` and returns `{name}({args})`, where args are recursively printed and joined with `", "`.
- C-004: `repo/sympy/printing/printer.py` dispatches to `_print_<class name>` before falling back to `emptyPrinter`.
- C-005: `repo/sympy/printing/codeprinter.py` records unsupported expressions only when `_print_not_supported` is reached.
- C-006: `repo/sympy/printing/numpy.py` defines explicit `_print_Min` and `_print_Max`, so NumPy vectorized behavior is not replaced by the inherited plain-Python known-function mapping.

## Formal Claims

The formal core is in `fvk/mini-pycode.k` and `fvk/pycode-printer-spec.k`.

- FC-001: `print(Fun("Min", Sym("a"), Sym("b")))` reaches `"min(a, b)"` with an empty unsupported set.
- FC-002: `print(Fun("Max", Sym("a"), Sym("b"), Sym("c")))` reaches `"max(a, b, c)"` with an empty unsupported set.
- FC-003: recursive argument printing is preserved, e.g. `Max(a, Min(b, c))` reaches `"max(a, min(b, c))"`.

## Adequacy Audit

- A-001: FC-001 passes I-001, I-002, I-003, and I-005: it states support for `Min`, the desired builtin spelling, and absence of unsupported tracking.
- A-002: FC-002 passes I-001, I-002, I-004, and I-005: it states support for `Max`, the desired builtin spelling, and absence of unsupported tracking.
- A-003: FC-003 passes I-003 and I-004 because both public suggested methods print every argument recursively; it prevents a too-narrow two-argument-only proof.
- A-004: No formal claim preserves the pre-fix `Min(a, b)` spelling or unsupported comment. That legacy behavior is marked as suspect by I-002.

## Public Compatibility Audit

- PCA-001: No public function signature or method signature changed.
- PCA-002: `user_functions` keeps precedence because `AbstractPythonCodePrinter.__init__` builds `self.known_functions = dict(self._kf, **user_functions)`.
- PCA-003: NumPy and SciPy printer behavior for `Min` and `Max` remains governed by explicit `_print_Min` and `_print_Max` methods in `NumPyPrinter`.
- PCA-004: `MpmathPrinter` now inherits support for `Min` and `Max` through the same `_known_functions` table. This is compatible with scalar mpmath use because Python builtins `min` and `max` accept scalar Python/mpmath values and require no import.

## Verdict

V1 satisfies the intent and proof obligations. No additional source change is justified by the FVK audit.
