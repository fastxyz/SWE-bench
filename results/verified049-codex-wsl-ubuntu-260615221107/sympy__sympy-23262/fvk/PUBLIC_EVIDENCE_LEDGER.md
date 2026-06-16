# Public Evidence Ledger

Status: constructed for audit, not machine-checked.

| ID | Source | Evidence | Semantic Obligation | Status |
|---|---|---|---|---|
| E1 | prompt | "Python code printer not respecting tuple with one element" | Singleton tuple source must preserve Python tuple semantics. | Encoded by I1, PO-2, claim `TUPLE-SINGLETON`. |
| E2 | prompt | `inspect.getsource(lambdify([], tuple([1])))` previously returned `return (1,)`; current buggy output was `return (1)` | Generated `lambdify` return source must include the comma for native one-tuples. | Encoded by I2, PO-5, claim `RETURN-SINGLETON-TUPLE`. |
| E3 | prompt | "missing comma after `1` that causes an integer to be returned instead of a tuple" | The observable property is return type/shape, not just text formatting. The model must distinguish `(1)` from `(1,)`. | Encoded by mini model's exact string result and Findings F-001. |
| E4 | prompt | "For tuples with two or more elements, the generated code is correct" and expected `return (1, 2)` | Multi-element tuple behavior is a frame condition to preserve. | Encoded by I3, PO-3, claim `TUPLE-MULTI`. |
| E5 | prompt hint | Workaround with SymPy `Tuple(1)` returns `return (1,)`; "the problem should also be fixed" | Native Python tuple rendering should match the already-correct singleton tuple syntax of SymPy `Tuple` for this observable. | Encoded by I1, I6. |
| E6 | source docstring | `_recursive_to_string` handles "non-SymPy types such as python lists and tuples" while avoiding printer calls for non-SymPy containers | The helper is the intended native list/tuple serialization point. | Encoded by SPEC target and claims over list/tuple rendering. |
| E7 | source | `_EvaluatorPrinter.doprint` assigns `str_expr = _recursive_to_string(self._exprrepr, expr)` then appends `return {str_expr}` | Correct container rendering must propagate into generated function source. | Encoded by PO-5 and `RETURN-SINGLETON-TUPLE`. |

