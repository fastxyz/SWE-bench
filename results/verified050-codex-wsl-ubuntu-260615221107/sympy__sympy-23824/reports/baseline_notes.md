# Baseline Notes

## Root cause

`kahane_simplify()` skips any free gamma matrices that appear before the first
contracted gamma matrix, because the Kahane graph algorithm is built to start at
the first contraction. Near the end of the function those leading free matrices
are restored by inserting each saved index at the front of every result list.

The restoration loop iterated from left to right while using `insert(0, ...)`.
For more than one leading free gamma matrix this prepended the later matrix in
front of the earlier one, reversing the original order. Thus
`G(rho)*G(sigma)*G(mu)*G(-mu)` simplified to
`4*G(sigma)*G(rho)` instead of preserving `G(rho)*G(sigma)`.

## Changed files

`repo/sympy/physics/hep/gamma_matrices.py`

Changed the loop that restores leading free gamma matrices to iterate from the
last skipped leading position back to the first. Since each index is still
inserted at position zero, reverse iteration preserves the original left-to-right
order in the final product. The adjacent comment was also corrected from
"trailing" to "leading" to match the behavior.

## Assumptions and alternatives

I assumed that positions before `first_dum_pos` are precisely the leading free
gamma matrices that should pass through unchanged. This follows from
`first_dum_pos = min(map(min, dum))`, which is the first contracted Lorentz index
position.

I considered replacing the side-effect list comprehension with an explicit loop
or bulk prefix concatenation. That would be clearer, but it would be a broader
style change than needed for this issue. Reversing the existing loop direction is
the minimal fix for the ordering bug.

I did not add or modify tests because the task states that the test suite is
fixed and hidden and that test files must not be changed.
