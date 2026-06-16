# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO1: Built-in container dispatch reaches explicit repr-printer methods

Claim: For Python built-in `dict`, `set`, and `frozenset`, `Printer._print`
selects `_print_dict`, `_print_set`, and `_print_frozenset`, respectively,
instead of falling through to `emptyPrinter`.

Evidence: `Printer._print` searches `_print_` plus each class name in the MRO;
V1 adds methods matching the built-in class names.

Status: discharged by source reasoning.

Findings: FVK-F1, FVK-F2, FVK-F4.

## PO2: Container members are recursively repr-printed

Claim: Dict keys, dict values, set elements, and frozenset elements are printed
through `self._print` or `self.doprint`, not through `str`.

Evidence: V1 `_print_dict` calls `self._print(key)` and
`self._print(expr[key])`; V1 `_print_set` calls `self.reprify(...)`; existing
`reprify` calls `self.doprint(item)`.

Status: discharged by source reasoning and modeled by K claims C-DICT,
C-SET-NONEMPTY, and C-FROZENSET-NONEMPTY.

Findings: FVK-F1, FVK-F2, FVK-F3.

## PO3: Output syntax remains executable Python container syntax

Claim: Dict output is `{key: value}` syntax; non-empty set output is `{elem,
...}` syntax; empty set output is `set()`; frozenset output is `frozenset()` or
`frozenset({elem, ...})`.

Evidence: V1 string templates use those forms directly. The empty-set special
case is required because `{}` is a dict literal.

Status: discharged by source reasoning and modeled by claims C-DICT,
C-SET-EMPTY, C-SET-NONEMPTY, C-FROZENSET-EMPTY, and C-FROZENSET-NONEMPTY.

Findings: FVK-F1, FVK-F2, FVK-F3.

## PO4: Unordered/semantic-container order is deterministic and justified

Claim: Built-in set elements and dict keys are ordered by `default_sort_key`
before printing.

Evidence: V1 uses `sorted(..., key=default_sort_key)`; existing string, latex,
and pretty printers also use `default_sort_key` for dict/set rendering.

Status: discharged as a default-domain printer convention. The issue imposes
recursive element rendering and executable syntax, not insertion-order display.

Findings: FVK-F5.

## PO5: SymPy `Dict` representation is not changed by the built-in dict fix

Claim: V1 does not add `_print_Dict`, so SymPy's immutable `Dict` class does not
start printing as a Python dict literal through this fix.

Evidence: `repr.py` contains `_print_dict` but no `_print_Dict`; dispatch for
`Dict` searches `_print_Dict` before fallback and will not match lowercase
`_print_dict`.

Status: discharged by source reasoning.

Findings: FVK-F6.

## PO6: The documented `eval(srepr(expr)) == expr` contract is preserved for the target containers

Claim: For target built-in containers containing values whose own `srepr` is
evaluable in the usual SymPy environment, the new container wrapper syntax is
also evaluable to an equal Python container.

Evidence: Dict/set/frozenset constructors and literals are Python-evaluable;
dict and set equality are element-based; frozenset equality is element-based.

Status: constructed proof obligation, not machine-checked.

Findings: FVK-F7.

## PO7: Public API and compatibility frame conditions are preserved

Claim: V1 changes no public signatures, settings, object printmethod priority,
or caller protocol.

Evidence: only private methods and one import were added to `ReprPrinter`;
`srepr(expr, **settings)` is unchanged.

Status: discharged by source reasoning.

Findings: FVK-F4, FVK-F6.
