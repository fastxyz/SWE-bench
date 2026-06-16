# FVK FINDINGS

Status: constructed, not machine-checked. Findings are based only on public
intent, source inspection, and constructed proof obligations.

## F-1: Pre-fix integer product overflow in the FMI denominator

- Classification: code bug, resolved by V1.
- Evidence: `benchmark/PROBLEM.md` identifies `tk / np.sqrt(pk * qk)` as
  producing `RuntimeWarning: overflow` and `nan` when `pk * qk` is too large.
- Concrete input class: any valid clustering whose contingency-derived
  nonzero counts satisfy `tk > 0`, `pk > 0`, `qk > 0`, and whose integer
  product `pk * qk` exceeds the active integer dtype range.
- Observed pre-fix behavior: the denominator product is evaluated as an
  integer before `np.sqrt`, so overflow can corrupt the denominator.
- Expected behavior: return the mathematical FMI value as a float.
- Proof link: PO-4 proves formula equivalence; PO-5 proves the V1 expression
  does not form the overflowing integer product.
- Code decision: keep V1 source expression unchanged.

## F-2: Nonzero branch requires positive denominators

- Classification: proof side condition, discharged.
- Evidence: the formula has divisions by `pk` and `qk`.
- Concrete input class: valid contingency counts with `tk > 0`.
- Observed V1 behavior under the side condition: evaluates `tk / pk` and
  `tk / qk`.
- Expected behavior: no division by zero.
- Proof link: PO-1 derives `tk <= pk` and `tk <= qk`; PO-3 derives
  `pk > 0` and `qk > 0` from `tk > 0`.
- Code decision: no extra guard needed; the count semantics already imply the
  denominators are positive on the nonzero path.

## F-3: Zero-pair branch must stay zero

- Classification: required boundary behavior, preserved.
- Evidence: public docs/tests show completely split labelings return `0.0`.
- Concrete input class: valid counts with `tk == 0`.
- Observed V1 behavior: returns `0.` before any division.
- Expected behavior: score `0.0` and no denominator evaluation.
- Proof link: PO-2.
- Code decision: keep the existing zero branch.

## F-4: Full NumPy/SciPy execution is outside the compact K fragment

- Classification: proof capability boundary, not a discovered source bug.
- Evidence: the source constructs a SciPy sparse contingency matrix and uses
  NumPy vectorized reductions; the FVK fast path models a reduced arithmetic
  kernel.
- Concrete input class: end-to-end label arrays, including platform-specific
  dtype behavior in earlier count squaring.
- Observed V1 behavior: count construction is unchanged from the public
  implementation; only the final score expression is changed.
- Expected behavior: the arithmetic tail should be correct once the counts are
  available.
- Proof link: PO-7 names the abstraction boundary.
- Code decision: no additional source change in this pass. A full proof would
  require a richer NumPy/SciPy semantics or a separate count-kernel proof.

## F-5: API and public-call compatibility

- Classification: compatibility check, discharged.
- Evidence: `fowlkes_mallows_score` remains exported through
  `sklearn.metrics.cluster` and `sklearn.metrics`; scorer wiring calls the
  same function object.
- Concrete input class: public callers using the existing function signature.
- Observed V1 behavior: no signature, return-shape, import, or dispatch change.
- Expected behavior: existing callers remain compatible.
- Proof link: PO-8.
- Code decision: no compatibility edit needed.

## Proof-derived findings from /verify

The constructed proof closes the arithmetic obligations PO-1 through PO-6 under
the count-domain assumptions. It does not close the richer NumPy/SciPy
end-to-end execution model named in F-4, so public integration tests over label
arrays should be kept until a richer model and actual `kprove` run exist.
