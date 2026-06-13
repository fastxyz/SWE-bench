# FVK notes — audit of the V1 fix for astropy__astropy-13579

This explains every decision taken during the FVK pass, tracing each to specific
entries in `fvk/FINDINGS.md` and `fvk/PROOF_OBLIGATIONS.md`. Bottom line: **V1 is
confirmed correct on its intended domain; the only code change in this pass is a
zero-risk explanatory comment.**

## What the audit did

I formalized `SlicedLowLevelWCS.world_to_pixel_values` as an intent-spec (`fvk/SPEC.md`):
the central contract `(W2P)` is the round-trip / inverse property (R) that the
issue's reproducer asserts, plus loop circularities `(BUILD)`/`(OFFSET)` for the
method's two `for` loops. The wrapped WCS's numerical inversion (`G∘F = id`) is
isolated as an explicit trusted oracle / `[ESCALATION BOUNDARY]` (PO8) rather than
proved or `[trusted]`-faked, per the FVK honesty discipline.

## Decision 1 — Keep the V1 algorithm (fill dropped world axes with the slice world coordinate)

- **Decision:** retain `sliced_out_world_coords = self._pixel_to_world_values_all(*[0]*len(self._pixel_keep))`
  and `world_arrays_new.append(sliced_out_world_coords[iworld])`.
- **Traceable to:** Finding **F1** (the V0 constant `1.` was wrong for two reasons:
  coupling leakage *and* SI-unit mismatch — `1 m` vs `~1.05e-10 m`, the exact
  `~1.8e11` error) and proof-derived **P1** (the substitution to `d` is precisely
  what makes obligations **PO3** (units correct by construction) and **PO4a/PO4c**
  (injected vector equals `F(combine_pix(a))`, so the oracle inverse returns `a`)
  discharge). The function proof in `fvk/PROOF.md` §2 step 4 is the formal
  statement of why this exact fill — and no other constant — closes `(W2P)`.
- **Why not an alternative fill** (e.g. `self.dropped_world_dimensions["value"]`):
  same numeric values but indexed by dropped-rank (needs an extra counter) and
  builds a heavier lazy dict; `_pixel_to_world_values_all(...)[iworld]` indexes by
  the full world index `iworld` directly, which is what the loop already has —
  see `fvk/SPEC.md` §2 and `fvk/ITERATION_GUIDANCE.md` G1.

## Decision 2 — Add an explanatory comment (the only source edit this pass)

- **Decision:** prepend a comment to `world_to_pixel_values` explaining that
  sliced-out world axes still need a value, that a non-trivial `PCij` couples them
  into the kept pixel result, and that the slice world coordinate (not an arbitrary
  constant) is used — and that a constant would also be in the wrong SI units.
- **Traceable to:** the **spec-difficulty signal** in `fvk/FINDINGS.md` (the spec
  for (R) is only clean *with* the `DECOUPLE`/units reasoning) and Findings
  **F1**+**F2**. This was the precise site of a subtle, high-impact bug; the
  "minimal refactor" allowance is best spent documenting the non-obvious rationale
  so a future edit does not regress to a placeholder. **PO3/PO4** are the
  obligations the comment narrates. Zero behavioral change, so no proof obligation
  is affected.

## Decision 3 — Do NOT add a coupled-axis (iterative) solver

- **Decision:** leave the coupled-axis case approximate (kept-pixel = 0
  evaluation), unchanged from V1.
- **Traceable to:** Finding **F2** + proof-derived **P2**, and obligation **PO4a**,
  which *does not discharge* without the `DECOUPLE` precondition. The audit shows
  this is **inherent to non-iterative inversion of a coupled slice**, *not*
  introduced by V1, and that the chosen evaluation pixel matches the pre-existing
  `dropped_world_dimensions` convention (`sliced_wcs.py:161`). It is **exact** on
  the reported WCS and all decoupled WCSs (the common case). An iterative fix is a
  larger change with a new termination obligation and is recorded as the open
  intent question **G2** in `fvk/ITERATION_GUIDANCE.md`, not actioned here. Keeping
  it out keeps the bug fix minimal and targeted.

## Decision 4 — Do NOT add a guard for `nworld == 1`

- **Decision:** no defensive guard around `sliced_out_world_coords[iworld]`.
- **Traceable to:** Finding **F3** and obligation **PO5**: the `else` branch is
  unreachable when `nworld == 1` because `__init__` forbids dropping the only world
  axis (`len(world_keep) >= 1`, `sliced_wcs.py:152-154`). The indexing is therefore
  only ever applied to a genuine multi-axis tuple. A guard for a provably
  unreachable case would add noise, so it is omitted; PO5 is discharged by the
  `[INV]` invariant instead.

## Decision 5 — Do NOT make `sliced_out_world_coords` lazy/conditional

- **Decision:** keep the unconditional computation on line 246.
- **Traceable to:** Finding **F4** — it is a pure performance consideration with
  **no correctness effect** (the value is simply unused when there is no dropped
  world axis), and it keeps the method branch-free and consistent with
  `dropped_world_dimensions`. Recorded as optional **G4**; not worth a behavioral
  edit in a bug-fix pass.

## Decision 6 — Recommend keeping all tests

- **Decision:** flag no test as removable.
- **Traceable to:** `fvk/PROOF.md` §7 and the honesty gate. The proof is
  *constructed, not machine-checked*, and rests on the unverified external oracle
  **PO8**. Out-of-domain (F5), coupled-axis (F2), `dropped_world_dimensions`, and
  integration tests are explicitly **not** subsumed. The audit's value here is
  Benefit 2 (Findings), not CI reduction.

## Residual risk (carried forward)

- **PO8 inversion oracle** (`G∘F = id`, WCSLIB + iterative solver) — trusted base,
  dominant risk, `[ESCALATION BOUNDARY]`.
- **`DECOUPLE` domain gap (F2)** — `(W2P)` proved on decoupled WCSs only.
- **Partial correctness** — solver termination (PO-T3) not proved.
- **Constructed, not machine-checked** — run the `kompile`/`kprove` commands in
  `fvk/PROOF.md` §6 to upgrade.

## Verdict

V1 stands. The audit confirms the V0→V1 substitution is the minimal change that
makes the round-trip contract `(W2P)` provable (PO3, PO4) and repairs the reported
failure exactly (PROOF §2 worked instantiation). The single new edit is a
documenting comment justified by the spec-difficulty/units finding (F1) and the
coupling subtlety (F2). No regeneration of the method is warranted.
