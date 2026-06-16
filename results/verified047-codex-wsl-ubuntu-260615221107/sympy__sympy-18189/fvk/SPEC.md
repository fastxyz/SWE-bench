# FVK Specification

Status: constructed, not machine-checked.

## Target

The audited unit is the `diophantine` entry path in
`repo/sympy/solvers/diophantine.py`, specifically the branch at lines 177-185
where a caller-provided `syms` order differs from the canonical sorted variable
order.

The full Diophantine classification and solving machinery is outside this
mini-model. It is represented by the abstract function `canonicalSolve(eq,
permute)`, whose contract is the existing `diophantine(eq, param,
permute=permute)` behavior when no `syms` remapping is requested.

## Public Intent Ledger

I-1. Source: `benchmark/PROBLEM.md`, lines 3-9.
Evidence: "`diophantine`: incomplete results depending on `syms` order with
`permute=True`", with the same equation returning a full signed/permuted set
for `syms=(m,n)` but only `{(3, 2)}` for `syms=(n,m)`.
Obligation: when `permute=True`, changing only `syms` order must not suppress
the applicable signed/value permutations.
Status: encoded in PO-2 and claim `DIOPHANTINE-SYMS-SPEC`, first claim.

I-2. Source: `diophantine` docstring, lines 124-132.
Evidence: "`syms` is an optional list of symbols which determines the order of
the elements in the returned tuple" and "`permute` ... permutations ... will be
returned when applicable."
Obligation: `syms` and `permute` are independent controls. `syms` determines
tuple ordering; `permute` determines expansion of the solution set.
Status: encoded in PO-2 and PO-3.

I-3. Source: `diophantine` docstring, lines 115-119.
Evidence: without `syms`, tuple elements are arranged according to the
alphabetic/default sorted variable order.
Obligation: the recursive solve used for remapping returns canonical-order
tuples, so remapping must index from canonical `var` positions into requested
`syms` positions.
Status: encoded in PO-3.

I-4. Source: public hint in `benchmark/PROBLEM.md`, lines 30-41.
Evidence: the branch called `diophantine(eq, param)` and "permute=True is lost
when `diophantine` calls itself."
Obligation: the recursive call in the `syms != var` branch must forward the
caller-provided `permute`.
Status: encoded in PO-2.

## Intent-Only Contract

For every equation `eq` accepted by `diophantine`, every parameter `param`, every
Boolean `p`, and every `syms` sequence that is a requested ordering of the
equation's canonical variables:

1. Let `var = sorted(free_symbols(eq), key=default_sort_key)`.
2. Let `S = canonicalSolve(eq, p)`, the solution set returned in `var` order
   when no `syms` remapping is needed.
3. If `syms != var`, `diophantine(eq, param, syms=syms, permute=p)` returns
   each tuple in `S` reindexed into `syms` order.
4. In particular, the recursive solve must be `canonicalSolve(eq, p)`, not
   `canonicalSolve(eq, False)`.

Preconditions for this audit:

- `syms` is a sequence after the public type check.
- The filtered `syms` names symbols from `var`; the primary proved family is the
  documented use where `syms` is a permutation/order of the equation variables.
- The underlying canonical solve is assumed to satisfy the existing solver
  contract. This proof checks the wrapper/remapping path, not the algebraic
  completeness of every equation class.

## Formal Spec English

Claim C-1: If `syms` is a permutation of `vars(eq)` and is not already in the
canonical order, then executing the syms-remapping branch with `permute=True`
returns `remapAll(canonicalSolve(eq, true), syms, vars(eq))`.

Claim C-2: Under the same branch condition, executing with `permute=False`
returns `remapAll(canonicalSolve(eq, false), syms, vars(eq))`.

Adequacy check:

- C-1 passes I-1, I-2, and I-4 because it keeps `permute=True` in the recursive
  solve and only reorders the resulting tuples.
- C-2 passes I-2 because it preserves the documented default base-solution
  behavior for `permute=False`.
- PO-3 passes I-2 and I-3 because the reindexing map is now built from canonical
  `var` tuple positions and iterated in requested `syms` order.

## K Artifacts

The machine-oriented fragments are:

- `fvk/mini-diophantine.k`: mini semantics for the audited branch.
- `fvk/diophantine-syms-spec.k`: two reachability claims for `permute=True` and
  `permute=False` in the `syms != var` branch.

They are intentionally small. The abstraction is property-complete for this
issue because it distinguishes `canonicalSolve(eq, true)` from
`canonicalSolve(eq, false)` and models tuple-order remapping as an observable.
