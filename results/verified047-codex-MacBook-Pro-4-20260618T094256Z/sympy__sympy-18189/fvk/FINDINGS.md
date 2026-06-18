# Findings

Status: constructed, not machine-checked.

## F1: Pre-fix recursive call dropped `permute=True`

Classification: code bug fixed by V1.

Input: `diophantine(n**4 + m**4 - 2**4 - 3**4, syms=(n,m), permute=True)`.

Observed pre-fix behavior from the public issue: `{(3, 2)}`.

Expected behavior from public intent: the complete signed/permuted solution set
in `(n,m)` tuple order, represented in the K artifact as `pow4_signed_nm`.

Mechanism localized by the K model: the `syms` reordering branch must first
solve canonically and then remap. If that canonical recursive solve receives
`PERM=false`, the branch reaches `pow4_base_nm`; if it receives the caller's
symbolic `PERM`, Claim C4 reaches `pow4_signed_nm` for `PERM=true`.

Decision: V1 addresses this by forwarding `permute=permute` in the recursive
call.

## F2: No V1 counterexample found in the audited branch

Classification: confirmation finding.

The constructed claims cover the branch V1 changed, the same-order frame, the
omitted-`syms` canonical frame, and the `permute=False` frame for the reordered
branch. No claim forces a source edit beyond V1.

Decision: keep V1 unchanged.

## F3: Full solver correctness is outside the bundled proof tier

Classification: proof capability gap / [ESCALATION BOUNDARY].

The artifact uses `canonical(EQ, P, PERM)` to represent the un-reordered
Diophantine solve. This is adequate for the issue because the verified property
is whether the caller's `PERM` value reaches that canonical solve before tuple
remapping. It does not verify the full Diophantine classification, factoring,
or solution-generation algorithms.

Recommended next proof work: replace `canonical` with a richer model of the
relevant equation classes if the goal becomes full solver verification.

## Proof-derived findings from `/verify`

No proof-derived finding requires a V2 code edit. The proof is constructed, not
machine-checked, so no test removal is recommended before running the emitted
`kprove` command and receiving `#Top`.
