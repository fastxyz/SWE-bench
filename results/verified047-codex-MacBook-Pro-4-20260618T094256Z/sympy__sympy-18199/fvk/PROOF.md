# Proof

Status: constructed (escalation-bounded).

No tests, Python, `kompile`, `kast`, `krun`, or `kprove` were run. Commands below are emitted for later checking only.

## Target

`repo/sympy/ntheory/residue_ntheory.py::nthroot_mod`

The proof models only the dispatch surface touched by the zero-residue fix. The pre-existing nonzero solver is abstracted as `nonzeroResult(A, N, P, AR)` so the proof can establish that V2 does not redirect nonzero inputs away from the old path.

## Claims

- `nthroot-mod-spec.k::Zero Scalar`: positive `N != 2`, positive prime `P`, and `A % P == 0` reach return value `0`.
- `nthroot-mod-spec.k::Zero List`: the same zero-residue class with `all_roots=True` reaches `[0]`.
- `nthroot-mod-spec.k::Square-Root Frame`: `N == 2` reaches the existing `sqrt_mod` abstraction.
- `nthroot-mod-spec.k::Nonresidue Frame`: nonresidues reach `None`.
- `nthroot-mod-spec.k::Composite Zero Frame`: composite zero-residue inputs for positive `N != 2` reach the existing not-implemented result.
- `nthroot-mod-spec.k::Nonzero Solver Frame`: nonzero prime residues reach the existing solver abstraction.

## Constructed Proof Sketch

For `N == 2`, the first rewrite rule applies and returns `sqrtResult(A, P, AR)`, matching the source-level delegation that remains before the new branch.

For positive `N != 2`, positive `P`, and `A % P == 0`, the V2 zero-residue rules apply before any call to `is_nthpow_residue`. If `isPrime(P)` is false, the result is `NotImplemented`, preserving composite-modulus behavior. If `isPrime(P)` is true, the result is `zeroRootResult(AR)`, which rewrites to `0` when `AR` is false and `ListItem(0)` when `AR` is true.

The scalar postcondition `isNthRoot(0, A, N, P)` simplifies because `powMod(0, N, P) == 0` for positive `N` and `P`, and `A % P == 0` by precondition. The list postcondition simplifies to the exact singleton zero-root list; exactness rests on the prime-zero uniqueness obligation described below.

For nonzero inputs, the guard `A % P == 0` is false, so the new zero-residue rules cannot fire. The model routes nonresidues, composite residues, and prime nonzero residues to the same abstract outcomes as before, establishing the regression frame.

## V1 Counterexample

V1 placed the zero-residue return after `is_nthpow_residue`. For `A = -17`, `N = 5`, `P = 17`, public intent applies because `A % P == 0`. V1 reaches `is_nthpow_residue(-17, 5, 17)`, whose source guard rejects `A < 0`; the zero-root return is never reached. This violates the intent ledger entry E2/E5. V2 avoids this by checking the zero-residue branch before that helper, with `N > 0` and `P > 0` guards.

## Escalation Boundary

`nthroot-mod-obligations.k::PRIME-ZERO-UNIQUE` records the theorem that for prime `P`, positive `N`, and `X**N == 0 mod P`, `X == 0 mod P`. This is mathematically standard by Euclid's lemma. It is not hidden with a trusted K rule; it is an explicit open obligation for a richer number-theory K theory.

## Exact Commands

From the workspace root:

```sh
cd fvk
kompile verification.k --backend haskell --main-module VERIFICATION -o nthroot-verification-kompiled
kast nthroot-mod-spec.k --definition nthroot-verification-kompiled --module NTHROOT-MOD-SPEC --sort Claim
kprove nthroot-mod-spec.k --definition nthroot-verification-kompiled --spec-module NTHROOT-MOD-SPEC
```

Expected proof result for the dispatch claims if these exact commands are run successfully:

```text
#Top
```

Optional open-obligation check, expected to require additional number-theory support:

```sh
kprove nthroot-mod-obligations.k --definition nthroot-verification-kompiled --spec-module NTHROOT-MOD-OBLIGATIONS
```

## Test Recommendations

Do not delete tests. Existing tests for nonzero roots, nonresidue `None`, and composite `NotImplementedError` remain useful until the emitted claims are actually machine-checked. A new public test would be appropriate for a negative zero-residue input such as `nthroot_mod(-17, 5, 17) == 0`, but this benchmark forbids modifying tests.
