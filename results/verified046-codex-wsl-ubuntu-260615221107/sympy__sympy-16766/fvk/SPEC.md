# FVK Spec: sympy__sympy-16766

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were executed.

## Scope

This FVK pass audits the V1 production change in
`repo/sympy/printing/pycode.py`:

- `PythonCodePrinter._print_Indexed`
- `PythonCodePrinter._print_Idx`

The observable under audit is the string returned by `CodePrinter.doprint`
through `pycode()` and Python-printer subclasses such as `LambdaPrinter`, plus
whether `_not_supported` contains `Indexed` or `Idx` for supported inputs.

There are no loops or recursive functions in the changed code. The proof
obligations are straight-line reachability obligations over printer dispatch,
string construction, and unsupported-set preservation.

## Intent Spec

I-001. For an `Indexed` expression that is valid Python subscript syntax,
`PythonCodePrinter` must print the expression directly instead of recording it
as unsupported.

I-002. The concrete reproduction `pycode(IndexedBase("p")[0])` must produce
`p[0]` without the "Not supported in Python: Indexed" preamble.

I-003. Multiple indices must be printed in the original index order and joined
with `", "` inside one Python subscript expression, for example `A[i, j]`.

I-004. Indices must be printed recursively with the active printer, so normal
printer behavior for symbols, integers, expressions, and reserved words is
preserved.

I-005. `Idx` objects used as indices must print as their labels; otherwise
supporting `Indexed` would still leave common indexed expressions partially
unsupported.

I-006. The change must not alter public call signatures, assignment codegen,
or non-Python language printers.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | `benchmark/PROBLEM.md` | "PythonCodePrinter doesn't support Indexed" | `Indexed` is in the intended domain of `PythonCodePrinter`. | Encoded by PO-001. |
| E-002 | `benchmark/PROBLEM.md` | `pycode(p[0])` currently prints a "Not supported" preamble followed by `p[0]`. | The preamble is the bug; `p[0]` is the desired code body. | Encoded by PO-001 and PO-004. |
| E-003 | `benchmark/PROBLEM.md` | Suggested method formats `"{}[{}]"` and joins indices with `", "`. | Preserve Python subscript form and index order. | Encoded by PO-003. |
| E-004 | `repo/sympy/tensor/indexed.py` | `Indexed.base` returns `args[0]`; `Indexed.indices` returns `args[1:]`; `IndexedBase.label` returns `args[0]`. | The printer can derive base code from the base label and index code from `expr.indices`. | Encoded by PO-001 and PO-003. |
| E-005 | `repo/sympy/tensor/indexed.py` | `Idx._sympystr` prints `Idx.label`. | `Idx` printing as the label is consistent with existing string semantics. | Encoded by PO-002. |
| E-006 | `repo/sympy/printing/printer.py` | Printer dispatch looks for `_print_<ClassName>` before falling back. | Adding `_print_Indexed` and `_print_Idx` prevents the generic unsupported path for those classes. | Encoded by PO-004. |
| E-007 | `repo/sympy/printing/codeprinter.py` | `_print_not_supported` records an expression in `_not_supported`; `doprint` emits the preamble from that set. | The bug is eliminated if supported `Indexed`/`Idx` inputs no longer reach `_print_not_supported`. | Encoded by PO-004. |
| E-008 | `repo/sympy/printing/lambdarepr.py` | `LambdaPrinter(PythonCodePrinter)` | The fix should reach lambdify string generation through inheritance. | Encoded by PO-005. |

## Formal Model

The companion K-style artifacts are:

- `fvk/mini-python-printer.k`
- `fvk/pycode-indexed-spec.k`

The model is intentionally small. It represents only:

- symbols and integer literals;
- `IndexedBase`, `Indexed`, and `Idx`;
- recursive render calls;
- comma-separated index rendering;
- a `supported` predicate for the printable fragment.

The model abstracts away the full SymPy object graph, module import tracking,
and every printer feature not touched by the patch. It keeps the relevant
observable: the rendered code string for supported `Indexed` expressions.

## Domain And Preconditions

The specified domain is:

- `expr` is an `Indexed` object with at least one index, as guaranteed by the
  `Indexed` constructor;
- the selected base representation and every index are printable by
  `PythonCodePrinter`;
- the required dependent index case includes `Idx(label)` where `label` is
  printable.

If a nested base or index is itself unsupported for Python code generation, the
existing recursive printer behavior may still record that nested expression as
unsupported. This is outside the issue's required fix and is preserved by the
recursive use of `self._print`.

## Postconditions

P-001. For `IndexedBase("p")[0]`, `pycode` returns exactly `p[0]` in human mode,
with no unsupported preamble.

P-002. For `IndexedBase("A")[i, j]` with printable indices, the rendered body is
`A[i, j]`.

P-003. For `IndexedBase("A")[Idx("i")]`, the rendered body is `A[i]` and neither
the `Indexed` nor the `Idx` expression is recorded as unsupported.

P-004. For the supported domain, `_not_supported` is unchanged by
`_print_Indexed` and `_print_Idx`; any unsupported entries can only come from
recursive printing of unsupported nested subexpressions.

P-005. Public method signatures and subclass dispatch remain compatible:
`_print_Indexed(self, expr)` and `_print_Idx(self, expr)` are ordinary printer
overrides, and `pycode(expr, **settings)` is unchanged.

## Adequacy Audit

| Formal obligation | Intent coverage | Result |
| --- | --- | --- |
| PO-001: print `Indexed` as subscript syntax | Matches I-001, I-002, I-003, E-001 through E-004. | Pass |
| PO-002: print `Idx` as its label | Required by I-004 and I-005; supported by E-005. | Pass |
| PO-003: preserve index order and comma-space separator | Matches I-003 and E-003. | Pass |
| PO-004: avoid `_print_not_supported` for supported `Indexed`/`Idx` | Matches I-001 and E-006/E-007. | Pass |
| PO-005: preserve compatibility and reach lambdify via inheritance | Matches I-006 and E-008. | Pass |

No required behavior is marked fail or ambiguous.

## Public Compatibility Audit

Changed public surface:

- Added printer override `PythonCodePrinter._print_Indexed(self, expr)`.
- Added printer override `PythonCodePrinter._print_Idx(self, expr)`.

Compatibility findings:

- No existing public signature was changed.
- `PythonCodePrinter`, `MpmathPrinter`, `NumPyPrinter`, `SciPyPrinter`,
  `SymPyPrinter`, and `LambdaPrinter` retain their constructors and public
  `doprint` behavior.
- `TensorflowPrinter` inherits from `AbstractPythonCodePrinter`, not
  `PythonCodePrinter`; it is not changed by this patch.
- Non-Python language printers already have their own `_print_Indexed` methods
  and are not changed.

Compatibility verdict: pass.
