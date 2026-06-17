# Public Evidence Ledger

| ID | Source | Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "Using `symbols` to create symbol-like objects like instances of `Function` ... creates objects of class `Symbol` instead of `Function` if there is an extra layer of parentheses." | `cls=Function` must be preserved through an iterable layer of `names`. | Encoded in `SPEC.md`, `symbols-spec.k`, PO1, PO3. |
| E2 | `benchmark/PROBLEM.md` | `q, u = smp.symbols(('q:2', 'u:2'), cls=smp.Function)` and `type(q[0])` expected `UndefinedFunction`. | Concrete expected result for the reproducer: `q[0]` is an undefined function class. | Encoded in claim `SYMBOLS-FUNCTION-NESTED-RANGES`. |
| E3 | `benchmark/PROBLEM.md` | "The extra layer of parentheses are necessary to deconstruct the output as separate tuples." | Preserve the outer iterable shape and per-range nested tuple structure. | Encoded in PO4 and the nested tuple claim. |
| E4 | `repo/sympy/core/symbol.py` docstring | "Despite its name, `symbols` can create symbol-like objects like instances of Function or Wild classes. To achieve this, set `cls` keyword argument to the desired type." | `cls` is a general constructor parameter, not a `Function` special case. | Encoded in PO3 general class-preservation obligation. |
| E5 | `repo/sympy/core/symbol.py` docstring | Examples show string, list, tuple, and set inputs preserving the corresponding container form. | The repair must not flatten or otherwise reshape iterable results. | Encoded in PO4 and compatibility audit C2. |
| E6 | `repo/sympy/core/function.py` | `Function.__new__` returns `UndefinedFunction(*args, **options)` when `cls is Function`. | If `symbols()` calls `Function(name, **args)`, the constructed object has undefined-function class behavior. | Used in PROOF.md step P5. |
| E7 | Implementation fact | `symbols()` receives `cls` as keyword-only and `args` contains only remaining keyword arguments. | Recursive calls using only `**args` lose `cls`; preserving `cls` requires an explicit `cls=cls` argument. | Encoded in finding F1 and PO3. |

SUSPECT legacy behavior: the issue's "Actual result" shows `Symbol`; this is
explicitly reported as the bug and is not used as expected behavior.
