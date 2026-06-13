# ITERATION_GUIDANCE.md — next-iteration feedback

Actionable feedback from the FVK audit of `SlicedLowLevelWCS.world_to_pixel_values`.
Each item: the evidence, the UltimatePowers-style question for the intent layer,
the recommended code/spec change, and tests.

---

## G1 — Root cause is resolved; lock it in (from F1 / P1 / PO3, PO4)

- **Evidence:** `(W2P)` now discharges (modulo the PO8 oracle) because V1 fills
  dropped world axes with the slice world coordinate `F(combine_pix(0))[iworld]`,
  which is unit-correct by construction and equals `F(combine_pix(a))` under
  `DECOUPLE`. V0's `1.` made PO3/PO4a false.
- **Question:** none — intent (R) is clear and met for decoupled WCSs.
- **Change:** **none beyond V1** (plus the explanatory comment added in V1). Do
  not revert to a constant fill.
- **Tests:** add/keep a decoupled round-trip regression (the `PROBLEM.md` WCS and
  the hint's `assert np.allclose(out[0], 0)`); keep it until `kprove` + the PO8
  oracle are accepted (honesty gate).

## G2 — Decide policy for *coupled* dropped axes (from F2 / P2 / PO4a) — the one real open question

- **Evidence:** `(W2P)` only proves universally under `DECOUPLE`. When a dropped
  world axis depends on a *kept* pixel axis, evaluating the dropped world value at
  kept-pixel = 0 (`d = F(combine_pix(0))`) is an approximation; the round-trip is
  off by the coupling term. This matches the long-standing `dropped_world_dimensions`
  convention but is not exact.
- **UltimatePowers question:** *"When a sliced-out world axis is coupled to a
  retained pixel axis, should `world_to_pixel_values` (a) return the current
  fixed-pixel approximation (fast, exact when decoupled), (b) iterate to solve the
  coupled system exactly, or (c) raise / warn that the result is approximate?"*
- **Recommended change (only if (b)/(c) is chosen):**
  - (b) **Iterative refinement:** seed with the current result `a₀`, recompute
    `d = F(combine_pix(a₀))[Dworld]`, re-solve, repeat to a tolerance. Localize to
    this method; guard with a max-iteration cap and fall back to `a₀`. Bigger
    change, new termination obligation — *out of scope for this bug fix.*
  - (c) **Document + optional warning:** add a docstring note that the inverse is
    exact only when dropped world axes are decoupled from kept pixel axes (the
    common case), matching `dropped_world_dimensions`.
- **Default for now:** keep V1 (option (a)); the reported bug is fully in the
  decoupled domain. The inline comment already records *why* the slice world
  coordinate is used.
- **Tests:** KEEP any coupled-axis test as an out-of-domain pin (F2); do **not**
  mark it redundant.

## G3 — `nworld == 1` safety is structural, not accidental (from F3 / PO5)

- **Evidence:** the `else` branch indexing `sliced_out_world_coords[iworld]` is
  only reached when `nworld ≥ 2` because `__init__` forbids dropping the only
  world axis (`len(world_keep) ≥ 1`).
- **Question:** none.
- **Change:** no guard needed. If future refactoring relaxes the `__init__`
  invariant, re-examine PO5.
- **Tests:** the existing `__init__` "at least one world dim" test protects this;
  keep it.

## G4 — Optional micro-optimization (from F4)

- **Evidence:** `sliced_out_world_coords` (a forward transform) is computed on
  every call, even with no dropped world axis.
- **Question:** *"Is `world_to_pixel_values` on a hot path where one extra forward
  transform per call matters?"*
- **Change (optional, perf-only):** compute it lazily/conditionally, e.g. only
  when `self.world_n_dim < self._wcs.world_n_dim` (there is a dropped axis).
  Correctness-neutral; skipped in V1 for readability and parity with
  `dropped_world_dimensions`.
- **Tests:** none.

## G5 — The inversion oracle is the dominant residual risk (from P3 / PO8)

- **Evidence:** the proof of (R) rests on `G∘F = id` for the wrapped WCS (WCSLIB +
  iterative solver) — an `[ESCALATION BOUNDARY]`, not machine-checked here.
- **Question:** *"Is the wrapped WCS's numerical inversion trusted to round-trip
  within tolerance on the queried domain?"*
- **Change:** none in this module. To raise assurance, escalate to integration
  tests against WCSLIB / numerical-tolerance assertions, or (long-term) a verified
  projection model — outside this kit's bundled tier.
- **Tests:** KEEP all numerical/engine tests until the oracle is independently
  justified.

---

## Summary for the next pass

The next code-generation pass should **keep V1 as the fix** (G1) and treat the
sole substantive open decision as **G2 (coupled-axis policy)** — an intent
question, not a defect. G3–G5 are confirmations/optional. No regeneration of the
method is warranted by this audit.
