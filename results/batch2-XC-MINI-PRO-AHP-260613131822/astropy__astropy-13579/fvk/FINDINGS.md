# FINDINGS.md — `SlicedLowLevelWCS.world_to_pixel_values`

Plain-language findings, each as `input → observed vs expected`. Findings from
`/formalize` first, then proof-derived findings from `/verify`. These do **not**
depend on machine-checking (FVK Benefit 2).

---

## Formalize findings

### F1 — `world_to_pixel_values` injected a wrong constant for sliced-out world axes  *(root cause; FIXED in V1)*

- **Where:** `sliced_wcs.py` line 254 (pre-fix): `world_arrays_new.append(1.)`.
- **Input:** the `PROBLEM.md` WCS (3D HPLN/HPLT/WAVE, `PC` couples WAVE pixel into
  the second spatial intermediate axis), sliced to one wavelength plane
  `SlicedLowLevelWCS(fits_wcs, 0)`; query the kept spatial world point that the
  forward transform produced at pixel `(0,0)`.
- **Observed (V0):** `world_to_pixel_values` returns `≈ 1.8e11` for the first
  (spatial) pixel axis.
- **Expected:** the round-trip value `49.5` (and `0` for the hint's reproducer).
- **Why it was wrong — two compounding reasons:**
  1. **Coupling.** With a non-trivial `PCij`, the value supplied for the dropped
     (WAVE) world axis leaks into the kept (spatial) pixel result via the inverse
     transform, so the dropped-axis fill is *not* a free placeholder.
  2. **Units.** The low-level API is in SI units, so `1.` is `1 metre` while the
     true slice wavelength is `≈1.05e-10 m`; the error scales by
     `1/CDELT3_SI ≈ 1/0.055e-10 ≈ 1.8e11`, matching the report exactly.
- **Spec trace:** violates claim `(W2P)` / intent (R): the left-hand world vector
  `embed_world(w_K, 1.0)` is not `F(combine_pix(a))`, so the oracle inversion does
  not return `combine_pix(a)`. See SPEC §7.
- **Fix (V1):** fill dropped world axes with the **slice world coordinate**
  `sliced_out_world_coords[iworld] = F(combine_pix(0))[iworld]`. This is in the
  correct units *by construction* (it is an output of `pixel_to_world_values`) and
  decouples correctly: under `DECOUPLE` it makes the injected vector equal
  `F(combine_pix(a))`, so the inverse returns `a`. **Classification: code bug,
  fixed.**

### F2 — Residual: round-trip is only exact when dropped world ⊥ kept pixels  *(known limitation; V1 unchanged)*

- **Input:** a WCS where a dropped world axis depends on a *kept* pixel axis
  (`DECOUPLE` false) — i.e. the `Dworld × Kpix` coupling block is non-zero.
- **Observed (V1):** `world_to_pixel_values` uses `d = F(combine_pix(0))`, the
  dropped world value evaluated at **kept pixel = 0**, which differs from the true
  `F(combine_pix(a))[Dworld]`; the kept pixel result is off by the coupling term.
- **Expected (ideal):** the dropped world value at the *true* answer `a`, which is
  unknown without iterating.
- **Assessment:** this is **inherent to non-iterative inversion of a coupled
  slice**, *not* introduced by V1, and *any* fixed choice of evaluation pixel is
  approximate. The chosen pixel (0) matches the long-standing convention already
  used by `dropped_world_dimensions` (line 161), so V1 is *consistent* with the
  rest of the class and is exact on the issue's WCS and on every WCS whose dropped
  axes are decoupled from the kept pixel axes (the overwhelmingly common case:
  spectral/stokes planes, independent axes). **Classification: underspecified
  intent / documented limitation — not a regression, no code change.** See
  `ITERATION_GUIDANCE.md` for the optional iterative upgrade and the UltimatePowers
  question.

### F3 — `nworld == 1` cannot reach the dropped-axis branch  *(positive finding / safety)*

- The `else` branch (line 256) indexes `sliced_out_world_coords[iworld]`. If the
  wrapped WCS had `world_n_dim == 1`, `_pixel_to_world_values_all` would return a
  bare array (not a tuple) and `[iworld]` would mean the wrong thing.
- **But** `__init__` guarantees `len(world_keep) >= 1` (lines 152–154); with
  `nworld == 1` the single world axis must be *kept*, so the `else` branch is
  **unreachable** and the indexing is only ever applied to a genuine multi-axis
  tuple. **Classification: precondition enforced upstream — no guard needed**
  (discharged as PO5).

### F4 — `sliced_out_world_coords` is computed unconditionally  *(minor; intentional)*

- Line 246 runs a forward transform on every call even when there is **no** dropped
  world axis (then the value is unused).
- **Impact:** one extra `pixel_to_world_values` evaluation; pure performance, **no
  correctness effect**. Mirrors `dropped_world_dimensions`, keeps the method
  branch-free and readable. **Classification: performance gap, accepted.** (Could
  be made lazy/conditional later; see `ITERATION_GUIDANCE.md`.)

### F5 — Out-of-domain inputs (projection singularities / NaN)  *(pre-existing; out of contract)*

- `world_to_pixel_values` is only an inverse where the wrapped transform is
  invertible. At projection singularities or for NaN inputs the result is
  undefined. V1 does not change this; the forward call on line 246 is as defined
  as the pre-existing `dropped_world_dimensions` call. **Classification:
  out-of-domain — keep any tests pinning this behavior.**

### F6 — Slice-offset interaction is consistent between forward and inverse  *(checked, OK)*

- For kept axes that are `slice(start, …)`, `_pixel_to_world_values_all` *adds*
  `start` (line 222) when computing `d`, and `world_to_pixel_values` *subtracts*
  `start` (line 263) from the returned pixels. Both V0 and V1 share line 263; V1's
  only new dependency is that `d` is computed at the same slice origin used
  forward, which it is. **Classification: no issue — symmetry verified** (PO7).

---

## Proof-derived findings (`/verify`)

### P1 — The proof needs `embed_world(w_K, d) == F(combine_pix(a))`; this is exactly what `d := F(combine_pix(0))` buys (under `DECOUPLE`)

- **Evidence:** claim `(W2P)`; the inversion oracle step `G(F(x)) = x` can only
  fire if its argument is literally a forward image. The V0 constant `1.` breaks
  this premise; V1's `d` restores it iff `DECOUPLE` holds.
- **Classification:** confirms the fix is *the* minimal change that makes the proof
  go through. Drives the `DECOUPLE` precondition into the contract.

### P2 — The `DECOUPLE` side condition is a *forced* precondition  →  bug-signal turned into a documented domain boundary

- **Evidence:** without `DECOUPLE` the Consequence step `F(combine_pix(a))[Dworld]
  = d[Dworld]` does **not** discharge (the two differ by the coupling term), so the
  proof of (R) cannot close universally.
- **Classification:** underspecified intent. Per FVK ("a side condition you are
  *forced* to add is usually a precondition the code silently assumed"), this is
  surfaced as F2 and routed to `ITERATION_GUIDANCE.md`, **not** papered over.

### P3 — The inversion law is an `[ESCALATION BOUNDARY]`, never `[trusted]`-faked

- **Evidence:** `F`, `G` are external numerical routines (WCSLIB + iterative
  solver). `G∘F = id` is assumed as the oracle (SPEC §6) and is the dominant
  residual risk; this repo's source cannot establish it.
- **Classification:** proof-capability gap / escalation boundary. Keep all tests
  that exercise the numerical engine until the oracle is independently trusted.

---

## Spec-difficulty signal (summary)

Writing a *clean, universal* spec for (R) was **not** possible without the
`DECOUPLE` precondition — and that difficulty is itself the finding (F2/P2): the
sliced inverse of a coupled WCS is only well-defined up to the choice of
evaluation pixel for the dropped axes. The fix makes the spec clean and exact on
the decoupled domain (which includes the reported case); the coupled domain is
explicitly out of the universal contract.
