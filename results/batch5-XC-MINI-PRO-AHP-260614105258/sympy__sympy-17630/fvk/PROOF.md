# PROOF — sympy__sympy-17630 (constructed, not machine-checked)

Constructed proof of the claims in `fvk/mini_matexpr-spec.k` against the mini-X
semantics in `fvk/mini_matexpr.k`, discharging the obligations in
`fvk/PROOF_OBLIGATIONS.md`. **No K toolchain is run here**; symbolic execution is
carried out on paper. The `kompile`/`kprove` commands that *would* machine-check
it are in §5.

Convention: `=>` is one or more semantic steps; uppercase `P,Q,K` are symbolic
`Int`s; functions reduce eagerly (they are `[function]`).

---

## 1. Lemma (REPZ) — the entry list is all-zero-like

Claim: `allZeroLike(repZ(P,Q,K)) => true` for `K ≥ 0`. *(O1)*

Guarded coinduction on `K` (the claim is its own circularity; the genuine step is
the `repZ` unfolding).

- **Base `K = 0`.** `repZ(P,Q,0) => .MVals`; `allZeroLike(.MVals) => true`. ✓
- **Step `K ≥ 1`.** `repZ(P,Q,K) => Z(P,Q), repZ(P,Q,K-1)` (genuine `=>⁺` step).
  Then
  `allZeroLike(Z(P,Q), repZ(P,Q,K-1)) => isZeroLike(Z(P,Q)) andBool allZeroLike(repZ(P,Q,K-1))`.
  `isZeroLike(Z(P,Q)) => true`. The second conjunct is the **circularity** applied
  to `K-1` (legal: a genuine step was taken; precondition `K-1 ≥ 0` follows from
  `K ≥ 1` by Z3). `true andBool true => true`. ✓

VC (Z3): `K ≥ 1 ⇒ K-1 ≥ 0`. Discharged. ∎

---

## 2. Theorem (ADD0) — a sum of zero blocks is a zero **matrix**

Claim: `addM(repZ(P,Q,K)) => Z(P,Q)` for `K ≥ 1`. *(C1; O2, O3, O4)*

```
addM(repZ(P,Q,K))
  => canon(rmId(repZ(P,Q,K)))                         [rule addM]
```

`repZ(P,Q,K)` with `K ≥ 1` unfolds (one step) to a non-empty list
`Z(P,Q), repZ(P,Q,K-1)`. Evaluate `rmId` on it:

```
rmId(Z(P,Q), repZ(P,Q,K-1))
  => headList(Z(P,Q), repZ(P,Q,K-1))                  [rule rmId, branch 1]
        requires allZeroLike(Z(P,Q), repZ(P,Q,K-1))   -- holds by (REPZ)
  => (Z(P,Q), .MVals)                                 [rule headList]
```

The `requires` of `rmId` branch 1 is exactly Lemma (REPZ), so the all-identities
branch fires. **This is the crux (O2): the head of the list is `Z(P,Q)` — a
`ZeroMatrix` — because no scalar `S.Zero` was ever prepended.** Then:

```
canon(Z(P,Q), .MVals) => Z(P,Q)                       [rule canon, singleton]
```

So `addM(repZ(P,Q,K)) => Z(P,Q)`. *(O3.)*

Shape correctness (O4): every element of `repZ(P,Q,K)` is `Z(P,Q)`, so the kept
head carries the common shape `(P,Q)`; in the real code `(P,Q) =
(rowblocksizes[i], colblocksizes[j])`, the intended block shape. ∎

VC (Z3): `K ≥ 1 ⇒ K ≥ 1` (non-emptiness) — trivially discharged.

---

## 3. Theorem (COLS-OK / COLSIZES-OK) — repeatability, no AttributeError

Claim: `cols(addM(repZ(P,Q,K))) => Q` for `K ≥ 1`. *(C2; O5)*

By Transitivity with (ADD0):

```
cols(addM(repZ(P,Q,K)))  =>  cols(Z(P,Q))             [by (ADD0)]
                          =>  Q                         [rule cols(Z(_,Q))]
```

The rule `cols(Z(_,Q)) => Q` exists, so the term is **not stuck**: a value `Q:Int`
is produced. *(O5.)* Lifting over the row (induction on the list, same shape as
(REPZ)) gives (COLSIZES-OK):

```
colsizes(addM(repZ(P,Q,K)), .MVals)
  => cols(addM(repZ(P,Q,K))), colsizes(.MVals)
  => Q, .IntList
```

so `BlockMatrix.colblocksizes` of the product returns `[Q]` (one block here),
i.e. it is **total**. *(O6.)*

**Composition to the real top-level (O7).** In `block_collapse(b*b*b)` →
`bc_matmul` → `(b._blockmul(b))._blockmul(b)`, the second `_blockmul` first
evaluates `self.colblocksizes == other.rowblocksizes`. `self` is the result of the
first `_blockmul`; by (COLS-OK) applied to each block, `self.colblocksizes`
evaluates to a list of `Int`s instead of getting stuck at `cols(s0)`. Hence the
guard is computed and the second multiply proceeds. `A ⊢ φ_pre ⇒ φ_post`. ∎

---

## 4. Counter-claim (BUG) — the proof of the defect

Claim attempted: `cols(addMbug(repZ(P,Q,K))) => Q` for `K ≥ 1`. **Expected to get
STUCK** — this is the constructed proof that the *base* code is wrong.

```
addMbug(repZ(P,Q,K))
  => canon(rmId(s0, repZ(P,Q,K)))                     [rule addMbug — PREPENDS s0]
```

`rmId(s0, Z(P,Q), repZ(P,Q,K-1))`: the list is still all-zero-like
(`isZeroLike(s0) => true`, plus (REPZ)), so branch 1 fires and keeps the **head**:

```
  => headList(s0, Z(P,Q), repZ(P,Q,K-1)) => (s0, .MVals)
canon(s0, .MVals) => s0
```

So `addMbug(repZ(P,Q,K)) => s0` (the scalar). Then:

```
cols(addMbug(repZ(P,Q,K))) => cols(s0)
```

and **there is no rule for `cols(s0)`** — the goal cannot advance. `kprove` would
report the residual obligation `cols(s0) => Q` (not `#Top`). That stuck term is
exactly:

> `AttributeError: 'Zero' object has no attribute 'cols'`

from the issue traceback (`blockmatrix.py:80`). The single difference between this
failing derivation and §2's succeeding one is **whether the post-processor
prepends the scalar `s0`** — i.e. precisely the line the fix changes. ∎

---

## 5. Reproduce the machine check (constructed only)

```sh
kompile fvk/mini_matexpr.k --backend haskell
kast    --backend haskell fvk/mini_matexpr-spec.k     # optional: parses to one AST
kprove  fvk/mini_matexpr-spec.k                        # expect #Top for REPZ, ADD0, COLS-OK, COLSIZES-OK
```

Expected: `#Top` for (REPZ), (ADD0), (COLS-OK), (COLSIZES-OK). The (BUG)
counter-claim is expected **not** to close (residual `cols(s0) => Q`); to see it
discharge against the *fixed* semantics, replace `addMbug` with `addM` in the claim.

**Trusted base / residual risk.**
- *Fragment adequacy.* The mini-X models the rm_id/unpack head-keeping behavior and
  the `.cols` partiality; it does not model the full `Add.flatten`, `Basic`, or the
  complete `MatAdd` rule set. The modeled rules are faithful to
  `matadd.py:129` (`rm_id`, `unpack`) and `strategies/rl.py:36-37` ("keep one").
- *Partial correctness.* Termination of the real `canonicalize` `exhaust` loop is
  assumed, not proved (E2).
- *Not machine-checked.* The proof is constructed; `#Top` from `kprove` would
  upgrade it. The FINDINGS (benefit 2) do not depend on the machine check.

---

## 6. Plain-language payoffs

- **Benefit 2 (bugs).** Constructing the proof pinpoints the defect to a single
  decision — *the post-processor prepended the scalar identity `S.Zero` before
  `MatAdd`'s `rm_id` "keep one" rule ran* — and renders the user's `AttributeError`
  as a concrete stuck state `cols(s0)` (§4). The fix is proven to remove exactly
  that prepend and nothing else (O8–O11).
- **Benefit 1 (tests).** With (ADD0)+(COLS-OK) machine-checked, the in-domain
  point tests for this behavior become redundant; see the test-redundancy table in
  `fvk/ITERATION_GUIDANCE.md` (conditioned on running §5; out-of-domain and
  integration tests are kept).
