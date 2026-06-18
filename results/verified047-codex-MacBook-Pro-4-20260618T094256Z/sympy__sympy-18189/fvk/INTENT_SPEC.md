# Intent Spec

Status: constructed, not machine-checked.

## Public Intent

For an in-domain Diophantine equation, `diophantine` returns a set of solution
tuples. The tuple positions follow the caller-provided `syms` order when `syms`
is supplied, otherwise the canonical sorted variable order is used.

When `permute=True`, applicable sign and value permutations are part of the
requested solution set. Changing only the order of `syms` must not remove those
permuted solutions; it may only remap tuple positions to match the requested
symbol order.

For the public issue equation
`n**4 + m**4 - 2**4 - 3**4`, the `permute=True` solution set shown for
`syms=(m,n)` has eight signed/permuted tuples. The call with `syms=(n,m)` is
reported as buggy because it returns only `{(3, 2)}` instead of the complete
permuted set in the requested tuple order.

## Domain And Side Conditions

The audited branch assumes `syms`, after filtering to equation variables, is a
complete permutation of the equation's free symbols. This is the intended use of
`syms` as an ordering argument and is the domain needed for tuple-position
remapping to be total.

The audit is partial correctness only. Termination of the full Diophantine
solver is not proved.

## Frame Conditions

The public `diophantine` signature and return shape must remain unchanged.

Calls with `syms` omitted must keep their canonical behavior.

Calls with `syms` already in canonical order must keep their canonical behavior.

Calls in the reordered-symbol branch with `permute=False` must keep using the
non-permuted canonical result, remapped only for tuple position.

## Out Of Scope For This Audit

The full correctness of all Diophantine solver classifications is represented
by the abstract `canonical(eq, param, permute)` result and is recorded as an
escalation boundary.
