# FVK Iteration Guidance

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Decision

Keep V1 unchanged.

The audit found that V1 directly discharges the proof obligations that matter
for the public issue:

- PO1 and PO2: tuple well-formedness and symbolic-component exit.
- PO3: numeric and exact-zero behavior preservation.
- PO4 and PO5: public symbolic fallback and argument-order independence.
- PO6: rejection of the `prec=None` alternative.
- PO7: compatibility.

## Next Code Action

No source edit is justified by the FVK findings. The current diff remains:
only two `else: raise NotImplementedError` branches in
`repo/sympy/core/evalf.py`.

## Next Test Action

Do not edit tests in this benchmark. In a normal SymPy workflow, add regression
coverage for the reported reversed-argument `Mul` case and, if acceptable for
the test style, its symmetric order.

## Machine-Check Action

When an environment with K exists, run:

```sh
cd fvk
kompile mini-evalf.k --backend haskell
kast --backend haskell evalf-fallback-spec.k
kprove evalf-fallback-spec.k
```

Keep any test-redundancy decisions conditional on `kprove` returning `#Top`.

## Open Risks

- The K model is an abstraction of the changed fallback classifier, not full
  Python or full SymPy evalf.
- The audit did not execute the reported expressions.
- Termination is not relevant to the changed branch, but the proof is still
  partial-correctness style.
