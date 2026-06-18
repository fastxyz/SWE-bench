# Formal Spec In English

Status: constructed, not machine-checked.

Claim C1 says: for any audited equation, parameter, and boolean `PERM`, calling
`diophantine` with no supplied `syms` returns the canonical solver result for
the same `PERM` value.

Claim C2 says: for any complete `syms` order that differs from the canonical
variable order, calling `diophantine` returns the canonical result computed with
the same `PERM` value, then remapped into the requested tuple order. The branch
does not replace `PERM` with `false`.

Claim C3 says: for any complete `syms` order that already matches canonical
variable order, calling `diophantine` returns the canonical result with the same
`PERM` value and performs no remap.

Claim C4 says: for the public issue equation with canonical order `(m,n)`, the
call using `syms=(n,m)` and `permute=True` reaches the complete signed/permuted
solution set in `(n,m)` tuple order.

Claim C5 says: for the same public issue equation and `syms=(n,m)`, using
`permute=False` reaches the non-permuted canonical base result in `(n,m)` tuple
order. This is the regression frame for calls that do not request permutations.

The side condition `completeSyms(SYMS, vars(EQ))` means the requested symbol
sequence contains every equation variable exactly once after the implementation's
filtering step.

The side condition `needsReorder(SYMS, vars(EQ))` means the supplied complete
symbol order differs from canonical variable order.

The side condition `sameOrder(SYMS, vars(EQ))` means the supplied complete symbol
order equals canonical variable order.

The frame condition is that the public API shape and canonical solver result are
not changed; only propagation of `PERM` through the existing recursive call is
under audit.

The proof is partial correctness only. Termination and full Diophantine solver
adequacy are escalation boundaries.
