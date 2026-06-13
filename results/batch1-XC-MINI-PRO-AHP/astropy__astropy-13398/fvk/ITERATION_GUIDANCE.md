# ITERATION GUIDANCE — astropy#13398 ITRS↔Observed

Feedback package for the next code-generation / intent-elicitation pass. Each item
ties to `FINDINGS.md` and `PROOF_OBLIGATIONS.md`. The kit's default is
**recommendation, not auto-patch**; the one change actually applied in V2 is called
out and justified.

## What V2 changed (and why it is safe)

- **Applied: `finite_difference_frameattr_name=None` on all four transforms.**
  - *Traces to:* Finding 4 + **PO8** (a/b/c).
  - *Why:* the transform is provably `obstime`-independent (PO8a), so the
    finite-difference "frame-induced" velocity is **exactly `0.0`** (PO8b); the default
    `'obstime'` setting computes that zero but executes `None + dt` and **crashes** when
    a *moving* object is sent to an observed frame left at `obstime=None` (the
    motivating satellite case). The change keeps only the exact re-orientation `M·V`
    (PO8c).
  - *Risk:* none. Bit-identical to V1 wherever V1 returned a value (PO8b ⇒ the deleted
    term was `0.0`); it only converts a crash into the correct result. No numeric test
    can observe the difference.

## Recommended next, NOT applied (with the open intent question)

### R1 — Explicit guard for distance-less input (Finding 1, PO9, P2.1/P3.1)
- **Recommended change:** at the top of `itrs_to_observed`/`observed_to_itrs`, detect
  `UnitSpherical`/`x.unit == u.one` and raise a clear error.
- **UltimatePowers question (blocks committing a guard):** *what is the intended
  contract for a direction-only ITRS/observed coordinate?* Options debated in the
  issue thread: **(a)** raise `ValueError` ("a topocentric ITRS↔observed transform
  needs a distance"); **(b)** assume the target is on the WGS84 geoid and proceed with
  a warning (@StuartLittlefair's suggestion). These give *different* observable
  behavior and *different* tests.
- **Why not applied now:** picking (a) vs (b) — and, for (a), the exact exception
  type/message — is an intent decision, not derivable from the code. Today the input
  **fails safe** (raises `UnitConversionError`), so there is no silent wrong answer to
  fix; applying a guess could contradict the maintainers' chosen contract. Surface,
  don't guess.

### R2 — Explicit guard for `location=None` (Finding 2, PO9, P1.1/P2.2/P3.2)
- **Recommended change:** raise a clear error when the observed frame has no
  `EarthLocation`.
- **UltimatePowers question:** same family as R1 — raise (which type/message) vs.
  default to geocentre? Fails safe today (`AttributeError`). Not applied for the same
  reason.

### R3 — `obstime`-mismatch policy (Finding 3, PO8a)
- **Recommended change (optional, UX):** when both frames carry a *differing*
  `obstime`, optionally emit a warning that it is being ignored and suggest
  `ITRS→ICRS→ITRS'` if a real time transform was intended.
- **UltimatePowers question:** *warn, raise, or stay silent on `obstime` mismatch?* The
  thread did not settle this. Correctness is unaffected (PO8a) — purely a UX choice;
  best handled in documentation. Not applied.

## Tests to add / keep / drop (mirror of `PROOF.md` §7)

- **Add (FAIL→PASS the spec proves):** round-trip exactness `ITRS↔AltAz`, `ITRS↔HADec`
  (PO3/PO4); anchor geometry (PO5/PO6); a **moving-object → `AltAz(location=...)` with
  `obstime=None`** test (pins the Finding-4 fix); `obstime`-independence (PO8a).
- **Keep:** out-of-domain error tests (Findings 1,2); float-tolerance tests (proof is
  exact in ℝ, rounding is trusted base); transform-graph integration/path tests.
- **Drop (only after machine-checking the `[ESC]` trig lemmas):** redundant
  single-point round-trip and single-geometry unit tests subsumed by PO3–PO6.

## Proof-capability gaps to close (not code bugs)

- **PC1:** the bundled K tier is integer/map/list; this code is **real linear algebra**.
  Machine-checking PO1/PO2/PO5/PO6 needs a real-closed-field / trig theory
  (`sin²+cos²=1`, complementary-angle identities) loaded into `kprove`. Until then those
  VCs are `[ESCALATION BOUNDARY]` — hand-verified, routed, **not** `[trusted]`. The
  round-trip VCs PO3/PO4 (the headline property) are already pure equational once ORTHO
  is granted, so they are the most readily machine-checkable.

## Bottom line

The core transform logic is **confirmed correct on its domain** (geometry + exact
round-trips + exact velocity) and is left unchanged. The only applied edit is the
zero-risk, audit-justified Finding-4 fix. All remaining findings are fail-safe
robustness/UX items that hinge on **intent questions** the maintainers must answer, so
they are surfaced as guidance rather than guessed into code.
