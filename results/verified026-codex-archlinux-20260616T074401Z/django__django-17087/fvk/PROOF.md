# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Machine-Check Commands

```sh
cd fvk && kompile mini-python-serializer.k --backend haskell
cd fvk && kast --backend haskell django-serializer-spec.k
cd fvk && kprove django-serializer-spec.k
```

Expected result after running the toolchain: `#Top`.

## Proof Sketch

The target has no loops, so no loop circularity is required. The proof is a
straight-line case split over the predicates used by
`FunctionTypeSerializer.serialize()`.

Case 1, lambda callable: the first branch checks
`value.__name__ == "<lambda>"` and raises
`ValueError("Cannot serialize function: lambda")`. This discharges PO-4 and the
K lambda claim.

Case 2, class-bound importable method: the branch predicate
`getattr(value, "__self__", None)` and `isinstance(value.__self__, type)` holds.
Let `klass = value.__self__`, `M = klass.__module__`,
`Q = klass.__qualname__`, and `N = value.__name__`. Under the side condition
`"<" not in Q`, V2 returns
`("%s.%s.%s" % (M, Q, N), {"import %s" % M})`. This discharges PO-1. If the class
is top-level, `Q == klass.__name__`, so the same step also discharges PO-3.

Case 3, class-bound local method: the class-bound predicate holds, but
`"<" in klass.__qualname__`. The success branch is skipped and V2 raises
`ValueError("Could not find function %s in %s.\n" % (N, M))`. This discharges
PO-2 and prevents a generated path containing `<locals>`.

Case 4, non-class-bound callable: the class-bound predicate is false and PO-4
does not apply. Execution reaches the existing no-module, importable-function,
and local-function checks unchanged. The importable-function subcase returns
`module + "." + value.__qualname__`, the local-function subcase raises the
"could not find function" `ValueError`, and the no-module subcase raises the
existing no-module `ValueError`. This discharges PO-5 by branch exclusion and
source framing.

PO-6 follows from source inspection: the method signature is unchanged, success
still returns a two-tuple, imports still use a set containing `import <module>`,
and no test files were edited.

## Residual Risk

The proof is partial correctness over a compact mini-semantics of the serializer
branch behavior. It assumes Python attribute access and type checks behave as
their names indicate. The proof has not been machine-checked because the task
forbids running K tooling.

## Test Recommendation

Do not remove tests. After machine-checking, direct point tests for PO-1 through
PO-4 would be logically subsumed by the proof, but test removal is only a
recommendation after `kprove` returns `#Top`. The benchmark also forbids editing
test files.
