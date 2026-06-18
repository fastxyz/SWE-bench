# Proof

Status: constructed, not machine-checked; escalation-bounded for full solver
internals.

## Artifacts

`mini-python.k` defines a minimal branch semantics for the relevant public
`diophantine` call shape.

`verification.k` adds concrete simplification facts for the public issue
equation and the two relevant `syms` orders.

`diophantine-syms-spec.k` contains the K reachability claims.

`diophantine-syms-obligations.k` records the explicit escalation boundaries.

## Exact Commands Not Run

The task says no K tooling may be executed. These are the commands to run in an
environment with K installed:

```sh
cd fvk
kompile verification.k --backend haskell --main-module VERIFICATION -o vk
kast diophantine-syms-spec.k --definition vk --module DIOPHANTINE-SYMS-SPEC --sort Claim
kprove diophantine-syms-spec.k --definition vk --spec-module DIOPHANTINE-SYMS-SPEC
```

Expected machine-check result if all claims discharge:

```text
#Top
```

This result was not obtained in this session.

## Claim C1: Canonical Omitted-`syms` Path

Claim C1 states that `diophantine(EQ, P, noSyms, PERM)` reaches
`canonical(EQ, P, PERM)`.

Symbolic execution applies the omitted-`syms` rule in `mini-python.k` directly.
The `PERM` variable is framed unchanged into the canonical result.

## Claim C2: Reordered `syms` Forwards `PERM`

Claim C2 states that when `SYMS` is complete and needs reordering,
`diophantine(EQ, P, SYMS, PERM)` reaches
`reorder(vars(EQ), SYMS, canonical(EQ, P, PERM))`.

Constructed proof:

1. Apply the reordered-`syms` semantic rule. This is the genuine progress step:
   `<k>` becomes `diophantine(EQ, P, noSyms, PERM) ~> remap(vars(EQ), SYMS)`.
2. Use Claim C1 as the function-contract circularity for the recursive
   canonical call, after that progress step. The recursive call reaches
   `canonical(EQ, P, PERM)`.
3. Apply the `remap` continuation rule. The final `<k>` item becomes
   `reorder(vars(EQ), SYMS, canonical(EQ, P, PERM))`.

The important verification condition is syntactic: the same symbolic `PERM`
appears in the recursive canonical call and in the postcondition. A pre-fix
model with `diophantine(EQ, P, noSyms, false)` would fail this claim for
`PERM=true`.

## Claim C3: Same-Order Frame

Claim C3 states that when `SYMS` is complete and already in canonical order,
`diophantine(EQ, P, SYMS, PERM)` reaches `canonical(EQ, P, PERM)`.

Symbolic execution applies the same-order rule directly. No recursive call or
remap is introduced, matching the V1 frame condition.

## Claim C4: Public Issue Instance

Claim C4 states that
`diophantine(pow4_mn_2_3, tparam, nm, true)` reaches `pow4_signed_nm`.

Constructed proof:

1. `vars(pow4_mn_2_3)` simplifies to `mn`.
2. `completeSyms(nm, mn)` simplifies to `true`.
3. `needsReorder(nm, mn)` simplifies to `true`.
4. Claim C2 reduces the call to
   `reorder(mn, nm, canonical(pow4_mn_2_3, tparam, true))`.
5. `canonical(pow4_mn_2_3, tparam, true)` simplifies to
   `pow4_signed_mn`, the eight-solution set anchored by the issue text.
6. `reorder(mn, nm, pow4_signed_mn)` simplifies to `pow4_signed_nm`.

The pre-fix behavior corresponds to replacing step 4's `true` with `false`,
which simplifies to `pow4_base_nm`, the one-solution legacy result.

## Claim C5: `permute=False` Frame

Claim C5 states that
`diophantine(pow4_mn_2_3, tparam, nm, false)` reaches `pow4_base_nm`.

The proof follows Claim C2 with `PERM=false`, then simplifies
`canonical(pow4_mn_2_3, tparam, false)` to `pow4_base_mn` and remaps it to
`pow4_base_nm`. This shows V1 does not accidentally request permutations for
callers that left `permute` false.

## Regression Decision

The only source behavior changed by V1 is the recursive call's preservation of
the caller's existing `permute` value in the reordered-`syms` branch. The claims
show that:

- `permute=True` now reaches the complete permuted set before remapping.
- `permute=False` still reaches the non-permuted base set before remapping.
- same-order and omitted-`syms` paths are frame-preserved.

No counterexample or unmet proof obligation requires a source edit beyond V1.

## Residual Risk

`canonical(EQ, P, PERM)` is an abstraction of the full SymPy Diophantine solver.
This proof does not verify factoring, classification, individual equation
solvers, expression expansion, exception behavior, or termination.

The proof has not been machine-checked. Test removal is not recommended unless
the exact `kprove` command returns `#Top` and the adequacy audit remains passing.
