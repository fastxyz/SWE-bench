# PROOF.md — constructed correctness proof of the `nthroot_mod` fix

**Status: constructed, not machine-checked.** The MVP builds the proof and emits the
`kompile`/`kprove` commands but does not run the toolchain (no execution environment in this
task either). The Findings (`FINDINGS.md`) and the math below do **not** depend on a machine
run; only the *test-removal* recommendation is gated on it.

Target: `nthroot_mod`, the V1 branch at `repo/sympy/ntheory/residue_ntheory.py:779–781`.
Specs/claims: `fvk/SPEC.md`. Obligations: `fvk/PROOF_OBLIGATIONS.md`.

---

## What is proved (plain language)

> For every prime `p`, every `n ≥ 1`, and every integer `a` with `a % p == 0`,
> `nthroot_mod(a, n, p, all_roots)` returns the **complete and correct** root set of
> `x**n ≡ a (mod p)`: `0` when `all_roots=False`, `[0]` when `all_roots=True` — because for
> a prime modulus that root set is exactly `{0}`.

This is `CLAIM-ZERO`. The surrounding guards establish its two preconditions (`isPrime(p)`,
`n ≥ 1`), so the claim's domain is exactly the set of inputs that reach the branch.

---

## The constructed proof

### Symbolic execution to the branch (Transitivity + Axiom + Case-Analysis)

Drive `PGM_nthroot` (SPEC.md §3) from the precondition state
`⟨env: a↦A, n↦N, p↦P, all_roots↦AR⟩` with `isPrime(P) ∧ N≥1 ∧ A modInt P == 0`:

1. `if (not isNthPowResidue) : return None` — on this domain `isNthPowResidue(A,N,P)` is
   `True` (Python `is_nthpow_residue` line 641: `a % m == 0 ⇒ return True`). Guard `false`;
   the `if false : return _` rule fires; **fall through**. (Frames `<env>`,`<out>` unchanged.)
2. `if (not isPrime(p)) : raise` — `isPrime(P)` holds, guard `false`; fall through.
   (This is where composite `p` would have raised — PO-FRAME-COMPOSITE.)
3. `if (a % p == 0) : return ([0] if all_roots else 0)` — evaluate the guard by `seqstrict`:
   `A % P ⇒ A modInt P ⇒ 0` (hypothesis), then `0 == 0 ⇒ true`. Guard `true` ⇒ the
   `if true : return E` rule fires; the conditional cools to `ListItem(0)` if `AR=true`, else
   `0`. The terminal `return` writes `<out> ⇒ #if AR then ListItem(0) else 0`. `<k> ⇒ .K`.

This is one genuine multi-step `=>⁺` execution with no loop and no recursion, so there is **no
circularity to discharge** here (the only loop in the real function, the gcd `while`, is on the
`else` path that this branch pre-empts; its correctness is ASSUME-SOLVE / PO-SOLVE, out of
scope). The proof obligation that remains is the single `ensures`, `roots(A,N,P) = {0}`,
discharged below; by Consequence it certifies the returned value is the contract value.

### §A — PO-ROOT and PO-EQUIV (`0` is a root, and the guard detects exactly that)

`powModP(0, N, P)` for `N ≥ 1` unfolds by the `[function]` rules:
`powModP(0,N,P) = (0 *Int powModP(0,N-1,P)) modInt P = 0 modInt P = 0`.
Hypothesis `A modInt P == 0`. Hence `powModP(0,N,P) = 0 = A modInt P`, so `0 ∈ roots(A,N,P)`
(**PO-ROOT**). Conversely `0 ∈ roots ⟺ powModP(0,N,P) = A modInt P ⟺ A modInt P = 0`, which is
exactly the branch guard (**PO-EQUIV**). Linear/`modInt` facts — Z3 tier.

### §B — PO-ONLY (`0` is the only root) — Euclid's lemma, discharged by hand

Goal VC: `isPrime(P) ∧ N ≥ 1 ∧ X ∈ [0,P) ∧ powModP(X,N,P) = 0 ⟹ X = 0`.

`powModP(X,N,P) = 0` means `P | X^N` (in ℤ). Euclid's lemma: for prime `P`, `P | u·v ⟹ P|u ∨
P|v`. Induct on `N ≥ 1`:
- `N = 1`: `P | X^1 = X` directly.
- `N → N+1`: `P | X^{N+1} = X · X^N ⟹ P | X ∨ P | X^N`; the right disjunct gives `P | X` by the
  induction hypothesis. Either way `P | X`.

So `P | X` with `0 ≤ X < P` forces `X = 0`. Therefore `roots(A,N,P) ⊆ {0}`; combined with §A
(`0 ∈ roots`), `roots(A,N,P) = {0}` — the `ensures` of `CLAIM-ZERO`. ∎

> **Honesty gate / escalation.** The *mathematics* here is certain and elementary. A *machine*
> discharge in K would require an inductive primality theory (`P prime`, divisibility,
> induction on `N`) that the bundled `[simplification]` tier does not include — so the machine
> step is an explicit **`[ESCALATION BOUNDARY]`** (FINDINGS PF2). It is **not** admitted as
> `[trusted]`; it is proved here by hand and flagged for later mechanization. The essential
> dependence on `isPrime(P)` is real: drop it and the lemma is false (`P=4,N=2,X=2`), which is
> precisely why PO-PRIME (the upstream `isprime` guard) is mandatory.

### §C — PO-COMPLETE / PO-SHAPE (returned value = contract value)

With `roots = {0}`: `all_roots=True` ⇒ contract `sortedList({0}) = [0]` = returned `ListItem(0)`;
`all_roots=False` ⇒ contract `min({0}) = 0` = returned `0`. Types: `0:Int`, `[0]:List` — match
all sibling branches. Closing the post-store equality uses the map-extensionality
`[simplification]` `{ M[k<-V] #Equals M[k<-V'] } => { V #Equals V' }` to reduce the `<out>`
cell equality to the scalar one already shown. ∎

### Preconditions discharged by guards (PO-PRIME, PO-NGE1)

Not arithmetic VCs but reachability facts about the guard chain; established in
`PROOF_OBLIGATIONS.md` (F2): `isprime` raises for composite `p` upstream; `is_nthpow_residue`
+ the `n==2`/`n==0` early exits guarantee `n ≥ 1` at the branch. These make `CLAIM-ZERO`'s
`requires` exactly the reachable-state set — the claim is not vacuous and not over-broad.

---

## `.k` artifacts and the (un-run) machine-check commands

Artifacts are embedded in `SPEC.md` (`nthroot.k` fragment semantics + the `*-spec.k` claims
`CLAIM-ZERO`, `CLAIM-RESIDUE-GUARD`, `CLAIM-PRIME-GUARD`, `ASSUME-SOLVE`). To machine-check
later, write them to `nthroot.k` / `nthroot-spec.k` and run:

```sh
kompile nthroot.k --backend haskell        # compile the fragment semantics (Haskell/symbolic backend)
kast    --backend haskell nthroot-spec.k   # (optional) confirm the claims parse to one AST
kprove  nthroot-spec.k                      # discharge the claims; expected: #Top  (all proved)
```

**Expected outcome (reasoned, not executed):** `CLAIM-RESIDUE-GUARD`, `CLAIM-PRIME-GUARD`,
and the symbolic-execution skeleton of `CLAIM-ZERO` reduce to `#Top` under the fragment + Z3.
`CLAIM-ZERO`'s `ensures` (`roots = {0}`) would **not** close on the bundled tier alone — it
needs the §B inductive-primality lemma supplied as a `[simplification]`/axiom; until that
theory is added, `kprove` would leave that one VC open. That open VC is the `[ESCALATION
BOUNDARY]`, **not** a defect in the fix (the lemma is true and proved by hand).

---

## Test-redundancy (benefit 1) — recommendation only, gated on machine-check

- **Subsumed once `CLAIM-ZERO` is machine-checked:** any pin of the form
  `nthroot_mod(k·p, n, p) == 0` / `… , True) == [0]` for prime `p`, `n ≥ 1` (e.g. the
  issue pin `nthroot_mod(289,5,17,True) == [0]`). The contract proves it for *all* such inputs.
  Recommendation only — **keep these tests until `kprove` returns `#Top`** (the §B lemma is
  hand-proved, not machine-checked).
- **Keep regardless (outside the verified contract):**
  - the `a % p != 0` exhaustive loop (`test_residue.py:176–187`) — that is PO-SOLVE territory,
    explicitly *assumed*, not proved here;
  - the composite-`p` `NotImplementedError` cases (lines 173–174) — out-of-domain pins;
  - the `n==2` cases — delegated to `sqrt_mod`, a different contract;
  - any termination/performance test — proof is partial-correctness only.

**Net:** this fix *adds* a small verified slice; it does not justify removing any existing
test (they all live outside `CLAIM-ZERO`'s domain, by construction — F PF4).

---

## Residual risk (must be explicit)

- **Partial correctness.** `CLAIM-ZERO`'s branch is straight-line (no loop) so it trivially
  terminates; the function's *other* paths (the gcd `while`) are out of scope (PO-SOLVE) and
  their termination is not addressed here.
- **Trusted base.** (i) Adequacy of the mini-X fragment as a model of the Python control flow
  reaching the branch; (ii) ASSUME-SOLVE — the untouched `_nthroot_mod1`/gcd paths assumed
  correct on `a%p≠0`; (iii) the §B inductive-primality lemma is hand-proved, machine-check
  pending; (iv) the standard reachability-logic metatheory + Z3 for the linear/`modInt` VCs.
- **"Constructed, not machine-checked."** No `kprove` was run; `#Top` would upgrade
  `CLAIM-ZERO` from *constructed* to *machine-verified* (modulo supplying the §B lemma).

**Bottom line:** every obligation that bears on the *fix itself* is discharged (by proof or by
upstream guard). The fix is correct; **V1 stands** (see `reports/fvk_notes.md`).
