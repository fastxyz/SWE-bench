# Intent Spec

Status: constructed, not machine-checked.

## Public intent

1. `srepr` must recursively print container contents using `srepr`-style representations. The issue shows this already works for list and tuple elements, and reports dict and set elements as wrong when they print as `x` and `y` instead of `Symbol('x')` and `Symbol('y')`.
2. Existing list and tuple behavior must be preserved: list output uses square brackets, tuple output uses parentheses, and singleton tuple output keeps the trailing comma.
3. For a Python dict, both keys and values are contents and must be recursively printed.
4. For a Python set, every member is a content value and must be recursively printed.
5. Empty set and empty dict output must remain valid Python spellings: `set()` for the empty set and `{}` for the empty dict.
6. `srepr` output is intended to be eval-friendly in an appropriate SymPy environment, per the module docstring and existing public test convention.
7. For unordered containers, exact member order is not the core reported defect. A deterministic `default_sort_key` order is an acceptable compatibility convention because other SymPy printers already use it for dict/set rendering.

## Default-domain assumptions

- Inputs under audit are finite Python containers whose members are themselves in the printable fragment modeled by the FVK artifacts.
- The proof is partial correctness: if the printer returns, the returned string satisfies the stated shape. Termination of arbitrary recursive object graphs is outside this issue.
- Full Python runtime behavior, subclass dispatch beyond the inspected public printer classes, and the internal ordering semantics of `default_sort_key` are treated as trusted implementation environment, not reimplemented in the mini semantics.
