# Intent Spec

Status: constructed, not machine-checked.

## Required behavior

I-1. A symbol created with `even=True` must have `.is_finite is True`.

Evidence: `benchmark/PROBLEM.md` reports `Symbol('m', even=True).is_finite`
as `None` and says a number should be finite before it can be even.

I-2. A symbol created with `integer=True` must have `.is_finite is True`.

Evidence: `benchmark/PROBLEM.md` gives the analogous
`Symbol('i', integer=True).is_finite` example.

I-3. The inference should be placed at the rational-number level, not only at
`integer`, `even`, or `odd`.

Evidence: the public hint says extending `rational -> real` to
`rational -> real & finite` is likely safe. In the old rules, integer already
implies rational and parity already implies integer.

I-4. The repair must not globally change old-assumption `real=True` into
`finite=True`.

Evidence: the public hint warns that old-assumption `real` currently behaves
more like an extended-real property and that adding `finite` to `real` would
probably break code.

I-5. A generic symbol with no numeric-set assumption must keep
`.is_finite is None`.

Evidence: `sympy/core/assumptions.py` documents that undetermined properties
return `None`; the issue only requires finiteness for number classes that
logically require it.
