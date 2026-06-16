# FVK Notes

The FVK audit kept the V1 source change unchanged. This decision is traced to
`fvk/FINDINGS.md` F-1 and F-3: the two new `else: raise NotImplementedError`
branches remove the uninitialized-local failure and make the `Mul` argument
order converge on the same public symbolic fallback path. The supporting proof
obligations are PO2, PO4, and PO5 in `fvk/PROOF_OBLIGATIONS.md`.

No additional source edit was made because PO1 and PO3 show that V1 preserves
the documented evalf tuple contract for exact-zero and numeric components, and
PO7 shows no public compatibility change. The source diff remains limited to
`repo/sympy/core/evalf.py`.

I rejected the public-hint alternative of assigning only `reprec = None` or
`imprec = None` for symbolic components. That decision is recorded as F-2 and
is justified by PO1 and PO6: the tuple contract constrains the real/imaginary
component slots themselves, so a symbolic component with a `None` precision
would still be malformed, while replacing the component with `None` would
misrepresent it as exact zero.

The proof artifacts are constructed but not machine-checked, as required by
PO8 and F-5. I did not run tests, Python, or K tooling, and I did not modify
test files.
