## FVK decision summary

The FVK audit confirms V1 and makes no additional source edit. The decision is
grounded in `fvk/FINDINGS.md` F1: the public issue reports `NameError` from an
unbound `cotm` read, and the public hint says the read should be `cothm`.
`fvk/PROOF_OBLIGATIONS.md` PO1 captures that exact discriminator requirement;
PO2 and PO3 capture the two existing branch results once the discriminator is
well-defined.

## Source decision

`repo/sympy/functions/elementary/hyperbolic.py` remains at the V1 change:
`if cothm is S.ComplexInfinity`. This keeps the computed `cothm = coth(m)` and
the following condition in the same local-name family. F1 marks the previous
`cotm` spelling as the resolved code bug, while F2 records that the allowed
evidence does not justify a broader refactor or return-formula change.

## Artifact decisions

The focused formal model in `fvk/mini-sympy-coth.k` and
`fvk/coth-eval-spec.k` targets the additive-period branch only. That scope is
chosen because F1 localizes the observed failure to the undefined-name read in
that branch. PO4 and PO5 record the frame and compatibility obligations that
support keeping unrelated `coth.eval` behavior unchanged.

## Verification status

The proof in `fvk/PROOF.md` is constructed, not machine-checked. F3 records the
environment constraint: no tests, Python, `kompile`, or `kprove` may be run in
this task. Because of F3, no test-removal recommendation is made; the guidance
is to keep tests and, outside this benchmark, add a regression test for the
reported substitution path.
