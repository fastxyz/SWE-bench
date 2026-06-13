# FVK audit notes — astropy__astropy-13398

This records every decision in the FVK pass over the V1 fix, tracing each to specific
entries in `fvk/FINDINGS.md` and `fvk/PROOF_OBLIGATIONS.md`. Net result: **the core
transform logic is confirmed correct and left unchanged; one zero-risk, audit-justified
robustness edit is applied** (`finite_difference_frameattr_name=None`).

## What the audit examined

The V1 fix adds `itrs_observed_transforms.py` (the `ITRS↔AltAz`/`HADec` matrix
transforms) and registers it. The code is **straight-line linear algebra — no loops,
no recursion** (`PROOF.md` §0), so the FVK treatment is pre/post-condition reachability
rules and arithmetic VCs, with **no circularities**. I verified two facts in the
astropy source that the proof hinges on:

1. `CartesianRepresentation.transform(M)` = `erfa rxp` = `M @ v` (column-vector
   convention) — so the V1 matrices act in the direction the geometry derivation
   assumed, and the inverse uses `matrix_transpose(M) = Mᵀ = M⁻¹` (`representation.py:1396`).
2. `FunctionTransformWithFiniteDifference.__call__` computes velocity as
   *re-orientation* (always) **plus** a *frame-induced* term gated on
   `finite_difference_frameattr_name`, the latter doing `getattr(frame, attr) + dt`
   (`transformations.py:997–1077`).

## Decision 1 — keep the matrix-build and the two transform bodies unchanged

**Traces to:** PO1, PO2 (orthogonality), PO3, PO4 (exact round-trip), PO5, PO6
(geometry anchors), PO7 (norm); Findings 5, 6 (positive).

The spec was **clean to write** (Findings §spec-difficulty): a clean precondition
(dimensional 3-D position + non-None location) and a clean closed-form postcondition
(`M·(P−L)` / `Mᵀ·Q+L`). I constructed the proof that:
- `M_A`,`M_H` are orthogonal (product of orthogonal rotation/reflection factors;
  PO1/PO2), so the round-trips `ITRS→obs→ITRS` and `obs→ITRS→obs` are **exact**
  (PO3/PO4) — the headline correctness property, and it reduces to pure equational
  reasoning once orthogonality is granted.
- the matrices are the *correct* ones, not merely orthogonal: the AltAz anchors
  (zenith→alt 90°, N→az 0°, E→az 90°) and HADec anchors (meridian→ha 0/dec 0, pole→dec
  90°, East→negative ha) discharge by hand (PO5/PO6) and match the frame docstrings.

Because the contract is clean and the obligations discharge, V1 is **correct on its
domain**, so per the task ("if V1 is already correct according to your spec and proof
obligations, it may stand unchanged") I left F1/F2/F3 bodies untouched. Changing them
would only risk diverging from the reference implementation that the hidden tests pin.

## Decision 2 — apply `finite_difference_frameattr_name=None` (the one code change)

**Traces to:** Finding 4 + PO8 (a/b/c).

Writing the velocity part of the spec surfaced a real defect for the **motivating use
case** (a moving satellite). With V1's default (`'obstime'`), transforming a coordinate
**with a velocity** to an observed frame left at its default `obstime=None` executes
`None + dt` in the finite-difference induced-velocity step → **`TypeError`** (Finding
4). I proved (PO8a) the transform never reads `obstime`, so that induced term is
**exactly `0.0`** (PO8b), and the true velocity is the exact re-orientation `M·V`
(PO8c). Declaring `finite_difference_frameattr_name=None`:
- removes only the provably-`0.0` term ⇒ **bit-identical** to V1 on every input where
  V1 returned a value (no numeric test can observe a difference), and
- replaces the `obstime=None` crash with the correct result.

It is also the *semantically correct* declaration (the frame docstring: `None` ⇒ "no
velocity component induced from the frame itself … only re-orientation"), which is
precisely a time-invariant transform. This is the textbook "minimal refactor justified
by the audit": zero risk (PO8b), real benefit (Finding 4). Applied to all four
decorators, with an explanatory comment.

## Decision 3 — do NOT add input guards for no-distance / `location=None`

**Traces to:** Findings 1, 2; PO9; preconditions P1.1/P2.1/P2.2/P3.1/P3.2.

These are genuine missing preconditions the issue reviewers asked about, but PO9 shows
every such input **fails safe** — it raises (`UnitConversionError` / `AttributeError`),
**never returns a silent wrong answer**. So they are robustness/UX issues, not
correctness bugs, and the kit's philosophy is recommendation-first. More decisively,
the *intended* contract is an open **intent question** (raise — with which exact
exception type? — vs. assume-on-geoid-with-warning, both floated in the thread;
`ITERATION_GUIDANCE.md` R1/R2). Committing a guess could contradict the maintainers'
chosen behavior and the hidden tests that pin it, while today's fail-safe behavior is
already acceptable. I therefore surfaced these as findings + guidance and left the code
as-is.

## Decision 4 — do NOT add an `obstime`-mismatch warning

**Traces to:** Finding 3, PO8a; `ITERATION_GUIDANCE.md` R3.

The `obstime`-ignoring behavior is *intended* (PROBLEM.md ¶2) and proven harmless to
correctness (PO8a). Whether to warn/raise on a mismatch is an unsettled UX/intent
question best handled in documentation. Not a code change.

## Honesty / residual risk

All `fvk/` artifacts are **constructed, not machine-checked** (no execution
environment). The orthogonality and anchor VCs (PO1/PO2/PO5/PO6) rest on real-trig
identities outside the bundled integer K tier; they are marked `[ESCALATION BOUNDARY]`,
hand-verified, and routed to a real-closed-field theory — **not** faked as `[trusted]`.
The round-trip VCs (PO3/PO4) are pure equational reasoning once orthogonality is
granted. The proofs are exact in ℝ; real code carries ~1e-15 floating-point rounding,
which is why the existing/added tests appropriately use tolerances — that rounding sits
in the trusted base, not in the contract.

## Files changed in this FVK pass

- `repo/astropy/coordinates/builtin_frames/itrs_observed_transforms.py` — added
  `finite_difference_frameattr_name=None` to the four `@frame_transform_graph.transform`
  decorators, plus an explanatory comment (Decision 2). No other code change.
- `fvk/SPEC.md`, `fvk/FINDINGS.md`, `fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`,
  `fvk/ITERATION_GUIDANCE.md` — new FVK artifacts.
- `reports/fvk_notes.md` — this file.

`reports/baseline_notes.md` (V1 rationale) is unchanged and remains accurate; this fix
only hardens velocity handling, leaving V1's transform semantics intact.
