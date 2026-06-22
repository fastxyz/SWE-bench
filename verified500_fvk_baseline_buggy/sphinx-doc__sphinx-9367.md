# sphinx-doc__sphinx-9367

- **Verdict:** B_COMPLETENESS — fvk fixed the *same* "1-element tuple loses its trailing comma" bug in a second, sibling code path (`visit_Subscript`) that baseline, the gold patch, and even the real upstream fix all missed.
- **Pitch-worthiness (1-5):** 5
- **Harness-verified regression test:** FAILS on baseline (RED), PASSES on FVK (GREEN), and FAILS on the official human fix (gold), via the official SWE-bench Docker harness.

## Benchmark Result

- Baseline arm: official SWE-bench evaluation marked the patch as resolved.
- FVK arm: official SWE-bench evaluation marked the patch as resolved.
- Audit category: baseline passed the benchmark but remained concretely buggy.

## The issue
`sphinx/pycode/ast._UnparseVisitor` turns a Python AST back into source text (used by autodoc to render default argument values and type annotations). Python requires a trailing comma to denote a 1-element tuple: `(1,)` is a tuple, `(1)` is just the integer `1`. Issue #9367 reports that `(1,)` was rendered as `(1)`, dropping the comma and silently changing a tuple into a scalar. The fix must keep the comma for the 1-element case while leaving `()` (0-tuple) and `(a, b, ...)` (n-tuple) unchanged.

## What baseline did
Baseline added a `len(node.elts) == 1` branch to `visit_Tuple()` returning `"(%s,)"`. This is correct and is **logically identical to the gold patch** for the reported case. Baseline explicitly considered the subscript path and *declined* to touch it (see `baseline_notes.md`: "I considered changing subscript tuple handling ... but that code intentionally removes tuple parentheses ... and is not needed for the reported `(1,)` failure"). That reasoning is half-right (it correctly must strip the *parens*) but it overlooked that the *comma* still matters.

## What fvk changed and why
fvk kept baseline's `visit_Tuple` fix **and** added a `render_simple_tuple()` helper inside `visit_Subscript()`, routing both the modern `node.slice` tuple branch and the legacy `ast.Index(...).value` branch through it. The helper appends a comma when the tuple slice has exactly one element. Rationale (fvk_FINDINGS F-002): a one-element *tuple slice* such as `obj[1,]` was being rendered as `obj[1]`, which is a different subscript (`__getitem__((1,))` vs `__getitem__(1)`) — the identical bug class as the headline issue, just in a sibling renderer that feeds the same `unparse()` output.

## FVK Formal Argument

- **FVK status:** constructed, not machine-checked.
- **FVK formal argument:** PO-3/PO-4: one-element tuple slices in subscripts must preserve tuple cardinality; the trailing comma is the semantic witness for a one-element tuple.
- **Why it catches baseline:** baseline preserves one-element tuple cardinality in `visit_Tuple()` but not in `visit_Subscript()`, so the proof obligation fails on the sibling unparse path.

## Concrete demonstration
Input source: **`obj[1,]`** (a subscript whose slice is the 1-element tuple `(1,)`; parses to `Subscript(slice=Tuple(elts=[Constant(1)]))`).

| Variant | Output | Round-trips to same AST? |
|---|---|---|
| Original (pre-fix) | `obj[1]` | **No** |
| **Baseline** | `obj[1]` | **No** — bug survives |
| **Gold (oracle)** | `obj[1]` | **No** — bug survives |
| **fvk** | `obj[1,]` | **Yes** — faithful |

Cited code (`sphinx/pycode/ast.py`, `visit_Subscript`):
- Baseline/gold/original keep `elts = ", ".join(self.visit(e) for e in node.slice.elts)` -> for one element yields `"1"` -> returns `obj[1]`.
- fvk's `render_simple_tuple` does `if len(value.elts) == 1: return elts + ","` -> yields `"1,"` -> returns `obj[1,]`.

Why it matters (runtime-verified): `p[1,]` calls `__getitem__((1,))` (tuple key), `p[1]` calls `__getitem__(1)` (scalar key) — these are genuinely different operations, so rendering `obj[1,]` as `obj[1]` is a correctness defect, not cosmetics. This path is reachable from real Sphinx usage: `sphinx/ext/autodoc/preserve_defaults.py` calls `unparse()` to render default arguments, so a signature like `def f(x=obj[1,]): ...` would be mis-rendered as `def f(x=obj[1]): ...`.

No regression: `is_simple_tuple` only fires when the slice is itself a `Tuple` AST node with >=1 element. Ordinary annotations are unaffected — `Tuple[int]` parses to a `Name` slice (not a tuple), `Tuple[()]` is an empty tuple, `np.ndarray[Any, ...]` is a multi-element tuple. Verified that `Tuple[int]`, `Tuple[int, int]`, `obj[1, 2]`, `Dict[str, int]` render unchanged under fvk.

## Why the tests missed it
- `tests.json` FAIL_TO_PASS is exactly one case: `test_unparse[(1,)-(1,)]`, and `gold_test.patch` adds only `("(1,)", "(1,)")` to `tests/test_pycode_ast.py`. That test exercises `visit_Tuple`, which baseline already fixed — so the hidden suite passes baseline and never touches `visit_Subscript`.
- There is **no test anywhere** (verified via grep over `tests/`) for a one-element tuple *subscript* (`obj[1,]`). The existing subscript tests (`Tuple[int, int]`) only cover the multi-element case, where original/baseline/gold/fvk all agree. Hence both baseline and fvk are scored "resolved" despite baseline retaining the subscript defect.

## FVK vs. Human Fix

**Human fix issue:** yes.

The human fix repairs tuple rendering in the reported path, but it does not repair the sibling `visit_Subscript` path. FVK preserves tuple cardinality there too, so `obj[1,]` does not collapse into `obj[1]`.

Gold (`gold.patch`) changes **only** `visit_Tuple`:
```python
     def visit_Tuple(self, node: ast.Tuple) -> str:
-        if node.elts:
-            return "(" + ", ".join(self.visit(e) for e in node.elts) + ")"
-        else:
-            return "()"
+        if len(node.elts) == 0:
+            return "()"
+        elif len(node.elts) == 1:
+            return "(%s,)" % self.visit(node.elts[0])
+        else:
+            return "(" + ", ".join(self.visit(e) for e in node.elts) + ")"
```
Gold does **not** touch `visit_Subscript`. fvk matches gold on this hunk (GOLD_MATCH = partial) and adds a strictly-additional `visit_Subscript` fix. I confirmed against the actual sphinx git history that even commit `b9158b96d` ("Fix #9364: 1-element tuple on the defarg is wrongly rendered" — the real upstream fix for this issue) left `visit_Subscript` using the plain `", ".join(...)`; the trailing-comma fix was **never** applied to the subscript path anywhere in the file's history. So fvk's extra change goes beyond what the Sphinx maintainers themselves shipped.

## Confidence & caveats
- **High confidence** the demonstration is correct: AST parsing, the three-variant render comparison, the round-trip check, and the runtime `__getitem__` distinction were all executed directly (Python 3.10). The `Tuple[int]`-vs-`obj[1,]` AST distinction is the load-bearing fact and is verified.
- fvk's change is correct and regression-free for the affected case; it is a genuine completeness improvement over both baseline and gold.
- **Honesty caveat:** fvk_FINDINGS.md / fvk_notes.md state the "formal proof" (K framework artifacts, `kprove`, etc.) was *constructed but never machine-checked* — no tooling was run. So the methodology's formal-verification claims are aspirational here; the *value delivered* is a real audit-driven completeness fix, not a machine-checked proof. The fix's correctness rests on my independent verification above, which holds.
- **Real-world impact is modest in frequency:** one-element tuple subscripts (`obj[1,]`) are uncommon in default args / annotations, so the practical blast radius is small — but when it occurs the output is unambiguously wrong, and fvk is the only variant that gets it right.
