# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

Do not edit `repo/sympy/printing/repr.py` further for this issue. The FVK audit
found that V1 directly addresses the reported root cause and does not create an
unjustified public compatibility change.

## Trace To Findings And Obligations

- Keep `_print_dict`: required by FVK-F2 and discharged by PO1, PO2, PO3, and
  PO6.
- Keep `_print_set`: required by FVK-F1 and discharged by PO1, PO2, PO3, PO4,
  and PO6.
- Keep `_print_frozenset`: justified by FVK-F3 and discharged by PO2, PO3, PO4,
  and PO6.
- Keep `default_sort_key` ordering: FVK-F5 resolves the ordering question using
  PO4 and sibling printer evidence.
- Do not add `_print_Dict`: FVK-F6 and PO5 identify SymPy `Dict` as a separate
  public container with existing representation behavior.
- Do not change public signatures or settings: PO7 is already discharged.

## Recommended Future Tests

Do not modify test files in this task. In a normal development branch, add or
confirm focused tests for:

- `srepr({x, y})` recursively printing `Symbol('x')` and `Symbol('y')`.
- `srepr({x: y})` recursively printing both key and value.
- Empty and non-empty built-in `set` syntax.
- Empty and non-empty built-in `frozenset` syntax.
- A regression check that SymPy `Dict` behavior is not accidentally changed by
  the built-in dict handler.

## Machine-Check Follow-Up

Run these commands only in an environment with K available:

```sh
kompile fvk/mini-srepr.k --backend haskell
kast --backend haskell fvk/srepr-container-spec.k
kprove fvk/srepr-container-spec.k
```

Expected result: `#Top`. Until then, treat the proof as constructed evidence,
not machine-checked verification.
