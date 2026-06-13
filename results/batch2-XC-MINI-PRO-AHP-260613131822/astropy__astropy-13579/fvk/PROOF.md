# PROOF.md — constructed proof for `world_to_pixel_values` (V1)

**Status: constructed, not machine-checked** (FVK MVP does not run
`kompile`/`kprove`). The proof discharges every obligation V1's edit is
responsible for; the external WCS inversion is an explicit trusted oracle
(`[ESCALATION BOUNDARY]`, PO8). Notation and claims are from `SPEC.md`;
obligations are referenced by `PO#` from `PROOF_OBLIGATIONS.md`.

---

## 1. What is proved (plain language)

> For a `SlicedLowLevelWCS` `sl` whose **dropped world axes do not depend on the
> kept pixel axes** (`DECOUPLE`), and any kept-pixel vector `a` in the wrapped
> WCS's invertible domain,
> `sl.world_to_pixel_values(*sl.pixel_to_world_values(*a)) == a`.

This is intent (R). It holds **exactly** for the `PROBLEM.md` WCS (the dropped
WAVE world axis depends only on the WAVE *pixel* axis, `PC3_* = [0,0,1]`), so the
reported failure is provably repaired. The proof is **partial-correctness**:
correct if the wrapped solver returns.

## 2. Function-level proof of `(W2P)` (Transitivity composition)

Let `a ∈ R^m` be a kept-pixel vector with `combine_pix(a)` in the invertible
domain, and let `w_K := sF(a) = F(combine_pix(a))[Kworld]` be the queried world
input (a genuine forward image).

1. **Entry / `d` computation (line 246).** `sliced_out_world_coords` evaluates to
   `d := _pixel_to_world_values_all(0,…,0) = F(combine_pix(0))`. One Axiom use of
   the helper's body; carries by framing. *(PO3 establishes `d[iworld]` is in axis
   `iworld`'s SI unit, because `d` is an output of `F`.)*

2. **Build loop (lines 251–256) via `(BUILD)`.** Used as a lemma instantiated at
   entry (`iworld=0`, `iworld_curr=−1`, `new=[]`). Its circularity (PO1, by
   guarded coinduction — the counter increment is the genuine `=>⁺` step; case
   split on `iworld in self._world_keep`) yields, on exit:
   `world_arrays_new = embed_world(w_K, d)`, i.e.
   - `Kworld` slots hold `w_K` **in order** (PO2: `iworld_curr` tracks
     `rank_Kworld`), and
   - `Dworld` slots hold `d[iworld]` (PO3).

3. **`broadcast_arrays` (line 258).** Value-preserving coercion (PO6); the
   mathematical vector is still `embed_world(w_K, d)`.

4. **Key Consequence — the injected vector is a forward image.** We must show
   `embed_world(w_K, d) = F(combine_pix(a))`:
   - **Kept axes (PO4b):** `embed_world(w_K,d)[Kworld] = w_K = F(combine_pix(a))[Kworld]`
     by definition of `w_K`. [STEP]
   - **Dropped axes (PO4a):** under `DECOUPLE`, `F(combine_pix(a))[Dworld]` is
     independent of `a`, so it equals `F(combine_pix(0))[Dworld] = d[Dworld] =
     embed_world(w_K,d)[Dworld]`. [Z3, given `DECOUPLE`]
   - Together: `embed_world(w_K, d) = F(combine_pix(a))`.  ∎(step 4)

   *This is the whole point of the fix.* In V0 the `Dworld` slots were `1.0`, so
   step 4 fails (`F(combine_pix(a))[Dworld] = d[Dworld] ≠ 1.0`, and unit-wrong):
   the proof cannot proceed — exactly Finding F1.

5. **Underlying inverse (line 259) via the oracle (PO8).** Apply
   `G(F(x)) = x` with `x = combine_pix(a)`:
   `pixel_arrays = G(embed_world(w_K,d)) = G(F(combine_pix(a))) = combine_pix(a)`.
   [ORACLE]

6. **Offset loop (lines 261–263) via `(OFFSET)`.** For each kept axis `i = Kpix[j]`
   that is a `slice` with `start = o`, subtract `o`:
   `combine_pix(a)[i] − o = (a[j] + o) − o = a[j]`; non-slice/None axes unchanged.
   (PO7, [COIND]+[Z3].)

7. **Select + unwrap (lines 266–270).** `tuple(pixel_arrays[ip] for ip in
   self._pixel_keep)` selects the `Kpix` components, giving `a`. The
   `pixel_n_dim == 1` unwrap returns the scalar `a[0]` when appropriate.

Chaining 1–7 by Transitivity: `A ⊢ φ_pre ⇒ (result = a)`, i.e. `sG(sF(a)) = a`.
**∎ (W2P, under `DECOUPLE` + `INVERTIBLE`, modulo oracle PO8).**

### Worked instantiation (the issue's numbers)

`m=2` kept pixel (HPLN,HPLT), dropped pixel WAVE at slice index `0`; `r=2` kept
world, dropped world = WAVE. `PC3_* = [0,0,1]` ⇒ WAVE world depends only on WAVE
pixel ⇒ `DECOUPLE` holds.
`d = F(combine_pix(0,0))`; `d[WAVE] = CRVAL3 + CDELT3·(0+1−CRPIX3)` in SI
`= 1.05e-10 m` (FITS pixel 1 = `CRPIX3`).
For `a=(49.5,12.0)` (0-indexed central pixel), `w_K = sF(a) = (0,0) arcsec`.
Step 4: injected `(0,0, 1.05e-10 m) = F(combine_pix(a))`. Step 5: `G` returns
`(49.5,12.0,0)`. Step 7: select ⇒ `(49.5, 12.0)`. The hint's reproducer
(`a=(0,0)`) gives `out[0]=0`. V0 instead injected `1.0 m`, yielding
`49.5 + (1.0−1.05e-10)/0.055e-10 ≈ 1.8e11`. ✓ matches both the bug and the fix.

## 3. Loop circularities (discharge sketch)

- **`(BUILD)`** (PO1): guarded coinduction over `range(nworld)`. Genuine step:
  counter `iworld → iworld+1`. Case split on `iworld ∈ Kworld`: kept branch
  `iworld_curr += 1; append(world_arrays[iworld_curr])`; dropped branch
  `append(d[iworld])`. Both re-establish the invariant on the shifted state;
  exit at `iworld = nworld` gives the full `embed_world`. Side condition
  `len(world_arrays) = #kept(nworld)` keeps the kept-branch index in bounds
  (linear, [Z3]).
- **`(OFFSET)`** (PO7): same shape over `range(npix)`; body subtracts `o_i` on
  slice-with-start axes. Invariant inductive; only linear VCs.

Neither loop has nonlinear or division VCs, so no `[simplification]` lemmas are
needed (unlike the `sum` template). The only nonlinear/opaque content is the
external `F`/`G`, isolated in PO8.

## 4. Residual risk

- **Partial correctness only.** Termination of the wrapped iterative solver
  (`G`, PO-T3) is not proved; the two `for` loops are trivially total but that is
  recorded as a recommendation, not a discharged measure.
- **Trusted base:**
  1. **The inversion oracle PO8** (`G∘F = id`) — WCSLIB + projection solver,
     numerical, outside mini-X. *Dominant risk.* Not `[trusted]`-faked; named.
  2. Adequacy of the mini-X fragment vs. real CPython/NumPy semantics
     (broadcasting, dtype) — modeled as value-preserving.
  3. The reachability metatheory / `kprove` / Z3, standard FVK trusted base.
- **`DECOUPLE` domain gap (F2):** `(W2P)` is proved on the decoupled domain only.
  For a WCS coupling a dropped world axis to a kept pixel axis, PO4a does not
  discharge and the round-trip is approximate. This is a documented limitation,
  not a defect introduced by V1 (V0 was strictly worse there too).
- **Constructed, not machine-checked:** see §6.

## 5. Findings surfaced (cross-ref `FINDINGS.md`)

F1 (root-cause constant, **fixed**), F2/P2 (`DECOUPLE` limitation, documented),
F3/PO5 (`nworld==1` safety), F4 (unconditional `d`, perf), F5 (out-of-domain),
F6/PO7 (offset symmetry), P1 (fix is the minimal proof-enabling change), P3/PO8
(oracle escalation boundary).

## 6. Reproduce the machine check (not run here)

```sh
kompile mini-wcs.k --backend haskell           # compile the fragment semantics
kast    --backend haskell mini-wcs-spec.k      # (optional) parse the claims
kprove  mini-wcs-spec.k                         # expected: #Top for (BUILD),(OFFSET)
                                                #          and (W2P) modulo the PO8 oracle axiom
```

`(W2P)` is dischargeable by `kprove` **only relative to** an assumed oracle axiom
`rule G(F(P)) => P [simplification]` (the trusted base, PO8) and the `DECOUPLE`
side condition; that axiom encodes the external WCSLIB inversion the kit does not
verify. Until these are run and the oracle independently justified, treat the
result as **constructed**.

## 7. Test-redundancy recommendation (Benefit 1) — conditioned on machine-checking

I cannot see the hidden suite; this maps *categories* of likely tests.

- **Would become redundant** *iff* `kprove` returns `#Top` **and** the PO8 oracle
  is accepted: single in-domain **decoupled** round-trip point assertions of the
  form "`world_to_pixel_values(forward(a)) == a`" — e.g. the `PROBLEM.md` /
  hint reproducer points — since `(W2P)` proves them for *all* such `a`. Est. CI
  saving is negligible (a handful of fast asserts); **the value here is Benefit 2,
  not test reduction.**
- **KEEP (not subsumed):**
  - the **coupled-axis** case (outside `DECOUPLE`) — out of the proved domain (F2);
  - **out-of-domain / singularity / NaN** behavior (F5);
  - **`dropped_world_dimensions`** and integration tests (the proof covers this
    unit, not the wiring);
  - **anything exercising the numerical engine** until PO8 is trusted.

**Recommendation: keep all existing tests.** The proof is *constructed, not
machine-checked* and rests on an unverified external oracle (PO8); per the FVK
honesty gate, do not remove any test on the strength of this proof. The payoff of
this audit is the Findings (F1 fixed, F2 documented), not CI reduction.
