# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

Keep the V1 source patch:

```python
if cothm is S.ComplexInfinity:
```

This is justified by Finding F1 and proof obligations PO1-PO3. The audit did
not surface a public-intent or proof-derived reason to edit additional source
code.

## Next Code Action

No further production-code change is recommended for this benchmark pass.

Do not edit tests in this task. In a normal development environment, add a
regression test that constructs `e = coth(log(tan(x)))` and checks that
`e.subs(x, n)` for representative reported integral values does not raise
`NameError`.

## Later Verification Action

In an environment with K available, run:

```sh
cd fvk
kompile mini-sympy-coth.k --backend haskell
kast --backend haskell coth-eval-spec.k
kprove coth-eval-spec.k
```

Keep all existing tests until those commands are run and broader proof coverage
exists. The current proof is constructed, not machine-checked, and covers only
the issue-localized additive branch.

## Open Risks

- The mini-semantics abstracts full SymPy expression evaluation and the
  recursive `coth(m)` call as `CothValue(M)`.
- The proof is partial correctness only.
- No execution-based validation was performed because the task forbids it.
