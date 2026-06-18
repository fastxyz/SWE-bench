# Srepr Container Spec

Status: constructed, not machine-checked.

## Scope

Target: `repo/sympy/printing/repr.py`, specifically `srepr`, `ReprPrinter.reprify`, existing list/tuple printing, and V1's added dict/set/frozenset/SymPy `Dict` printers.

The modeled input domain is finite acyclic containers made from symbols, strings, lists, tuples, sets, frozensets, Python dicts, and SymPy `Dict` wrappers. Full Python object identity, mutation, exceptions, and arbitrary custom printer methods are outside the mini semantics.

## Developer-readable contract

- `srepr(Symbol('x'))` prints `Symbol('x')`.
- `srepr([x, y])` prints `[Symbol('x'), Symbol('y')]`.
- `srepr((x, y))` prints `(Symbol('x'), Symbol('y'))`.
- `srepr({x, y})` prints set contents with recursive `srepr` spelling, modeled for the x/y issue case as `{Symbol('x'), Symbol('y')}`.
- `srepr({x: y})` prints both key and value recursively, modeled as `{Symbol('x'): Symbol('y')}`.
- `srepr(set())` prints `set()` and `srepr({})` prints `{}`.
- `srepr(frozenset({x}))` prints `frozenset({Symbol('x')})`.
- `srepr(Dict({x: y}))` prints `Dict({Symbol('x'): Symbol('y')})`, preserving the SymPy wrapper in the repr form.

## Ordering rule

Python sets and dicts are unordered for this issue's semantic purpose. The formal model uses abstract `sortVals` and `sortPairs` functions to represent `default_sort_key` ordering. Concrete x/y claims reduce to x before y. This ordering is compatibility-derived from other SymPy printers; the core intent-derived obligation is recursive member printing.

## Frame conditions

- Existing list and tuple recursive output remains unchanged.
- Empty set remains `set()` rather than `{}`, avoiding ambiguity with empty dict.
- Empty dict remains `{}`.
- No public method signatures are changed.
- PythonPrinter inheritance remains compatible because symbol rendering still dispatches to `PythonPrinter._print_Symbol` inside inherited container methods.

## Ledger mirror

The controlling public evidence is:

- E1: list and tuple examples are correct and must be preserved.
- E2: dict and set examples are wrong and require recursive content printing.
- E3/E6: `srepr` should remain eval-friendly in an appropriate environment.
- E5: `default_sort_key` ordering is the established printer convention for unordered containers.
- E8: the pre-fix `{x, y}` and `{x: y}` displays are SUSPECT legacy behavior.
