# FVK PROOF

Status: constructed, not machine-checked. No Python, tests, `kompile`, `kast`,
or `kprove` commands were executed.

## Claims

The formal core is represented by:

- `fvk/mini-pycode-unparse.k`: a minimal string-rendering semantics for the AST
  shapes under audit;
- `fvk/pycode-ast-tuple-spec.k`: claims for one-element tuple rendering,
  one-element subscript tuple-slice rendering, and frame behavior for empty and
  multi-element tuples.

## Constructed Proof

PO-1 is discharged by case analysis on `len(node.elts)` in
`visit_Tuple()`. When the length is exactly one, the first branch is selected and
returns `"(%s,)" % self.visit(node.elts[0])`. This is precisely
`"(" + visit(E) + ",)"`, so the direct one-element tuple claim reaches the
postcondition.

PO-2 is discharged by the remaining `visit_Tuple()` branches. If `node.elts` is
truthy after the one-element branch has failed, the length is at least two and
the code returns the existing parenthesized comma-and-space join. If `node.elts`
is empty, the code returns `"()"`. These branches preserve the public empty and
multi-element tuple behavior.

PO-3 is discharged by case analysis inside `visit_Subscript()`. For direct
`node.slice` tuple nodes, `is_simple_tuple(node.slice)` requires an `ast.Tuple`,
at least one element, and no starred elements. The selected branch calls
`render_simple_tuple()`. If the tuple has exactly one element, that helper
returns the joined child rendering plus `","`; `visit_Subscript()` then wraps it
in brackets, yielding `visit(value) + "[" + visit(E) + ",]"`.

PO-4 is discharged by the same helper and by branch framing. If the simple tuple
slice has two or more elements, `render_simple_tuple()` returns only the
existing comma-and-space join, so `Tuple[int, int]`-style output is unchanged.
If the slice is empty, starred, or not an `ast.Tuple`, the existing generic slice
path is used. The `ast.Index` branch repeats the same helper call for older AST
versions, so the proof obligation is not version-specific.

PO-5 is discharged by diff inspection. The patch changes no public helper
signature, no visitor method signature, and no caller contract. All call sites
continue to call `unparse()` or visitor methods as before and receive strings.

PO-6 is discharged procedurally. This file records constructed proof steps and
commands, but does not assert a machine-checked result or recommend test
deletion without running the commands later.

## Machine-Check Commands

These commands are the expected FVK toolchain steps. They were not run.

```sh
cd fvk
kompile mini-pycode-unparse.k --backend haskell
kast --backend haskell pycode-ast-tuple-spec.k
kprove pycode-ast-tuple-spec.k
```

Expected result if the mini semantics and claims are accepted and discharged:
`#Top`.

## Test Guidance

The public suggested testcase `("(1,)", "(1,)")` is subsumed by PO-1 after a
successful machine check. A subscript tuple-slice testcase such as `("obj[1,]",
"obj[1,]")` would be covered by PO-3. Existing empty tuple, multi-element tuple,
and `Tuple[int, int]` tests remain useful until the proof is machine-checked and
should not be deleted in this benchmark.

## Residual Risk

The proof is partial and constructed over a minimal string-rendering model, not
a full Python AST semantics. The model is property-complete for this issue
because it preserves the relevant observable axis: rendered string shape for
tuple cardinality. It does not prove unrelated AST visitors, parser behavior,
termination, or integration behavior.
