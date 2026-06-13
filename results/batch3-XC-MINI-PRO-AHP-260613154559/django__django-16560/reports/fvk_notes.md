# reports/fvk_notes.md — FVK audit outcome for django__django-16560

## Summary verdict

**V1 stands unchanged.** Applying `/formalize` + `/verify` to the V1 fix produced
five `fvk/` artifacts and two `.k` files. Every proof obligation in
`fvk/PROOF_OBLIGATIONS.md` (PO1–PO14) is discharged (constructed, not
machine-checked), and no entry in `fvk/FINDINGS.md` is a code bug. No source edit was
required or made in this pass. Below, each part of the V1 fix and each "keep
unchanged" decision is traced to the specific findings and obligations that justify
it.

## Why no code changed

The fix is small, additive, **loop-free and recursion-free**. The FVK exercise
therefore reduced to: (a) does the new code do what the issue asks for *all* inputs,
and (b) does it preserve every legacy behavior. Both held under the constructed
proof, so the "confirm" branch of the task applies. Crucially, the one place this
class of change usually breaks — emitting a new field from `__eq__` but forgetting
`deconstruct()` (or vice-versa) — was made an explicit obligation and **passed**.

## Decision-by-decision trace

### D1 — Keep the `BaseConstraint.__init__` code guard (`if ... is not None`)
- Traces to: **PO1** (`(INIT-CODE)`), **F4**.
- The guarded assignment yields effective code `= C` for *all* `C` including `None`
  (proof `PROOF.md §2`, clean universal postcondition). The guard also preserves any
  class-level default a subclass might set (parallel to `default_violation_error_message`).
  Keeping the guard (rather than an unconditional `self.violation_error_code = ...`)
  is the correct, more flexible choice. **No change.**

### D2 — Keep `violation_error_code` out of the deprecated `*args` list
- Traces to: **F1**, **PO-domain note in SPEC.md**.
- `violation_error_code` is keyword-only by design; it was never a historical
  positional, so the `zip(args, ["name", "violation_error_message"])` list is left
  intact. F1 confirms this is correct and a no-op on the verified domain. **No change.**

### D3 — Keep the `deconstruct()` emission `if self.violation_error_code is not None`
- Traces to: **PO3, PO4** (`(DECON-CODE)`), **F3**, **PV2**.
- Emits the code iff non-`None`; when `None`, kwargs are byte-identical to baseline
  (PO4), so existing deconstruction tests are unaffected. This emission is *required*
  for the round-trip (D4). **No change.**

### D4 — Confirm the `deconstruct`↔`__eq__` round-trip (the load-bearing check)
- Traces to: **PO5, PO6** (`(ROUNDTRIP-CODE)`), **F3**, **PV2**, `PROOF.md §4`.
- `clone(c) == c` holds for custom-code constraints because V1 *both* emits the code
  in `deconstruct()` *and* compares it in every subclass `__eq__`, using the same
  attribute name. The counterfactual (emit-without-compare or compare-without-emit)
  was shown to fail the round-trip claim — V1 avoids it. This is the single most
  important confirmation of the audit. **No change.**

### D5 — Keep `code=self.violation_error_code` on the four in-domain raise sites
- Traces to: **PO9** (`(VALIDATE-CODE)`), **PO14** (coverage), `PROOF.md §5`.
- `CheckConstraint.validate` (constraints.py:130), `UniqueConstraint.validate`
  expressions (423) and condition (441), and both `ExclusionConstraint.validate`
  branches now bind the raised error's `code` to the effective code. Enumeration in
  `PROOF_OBLIGATIONS.md` confirms 3/3 subclasses and 5/5 in-domain sites. **No change.**

### D6 — Keep the field-only `UniqueConstraint` branch raising the legacy code
- Traces to: **PO10**, **F5**, **G1**, `PROOF.md §7`.
- `UniqueConstraint(fields=..., condition=None)` (constraints.py:432) deliberately
  keeps `instance.unique_error_message(...)` (codes `"unique"`/`"unique_together"`).
  This mirrors the long-documented exclusion for `violation_error_message`; applying
  the custom code there would break legacy field-unique tests and require an
  out-of-scope change to `Model.unique_error_message`. The new code's docs state the
  same exclusion. **Deliberately unchanged.**

### D7 — Keep the `__repr__` code slot ordered before the message slot
- Traces to: **PO11, PO12** (C6), `PROOF.md §7`.
- All three `__repr__`s render the code slot as `""` exactly when
  `violation_error_code is None`, so legacy repr output is byte-identical when no code
  is set (PO11) and shows `" violation_error_code=%r"` before the message when set
  (PO12). I additionally re-verified the `%`-format slot counts match the argument
  tuples (Check 5/5, Unique 10/10, Exclusion 9/9) — no format-string runtime bug.
  **No change.**

### D8 — Keep the migration-serializable assumption undocumented-as-code
- Traces to: **F6**, **G3**.
- A non-serializable custom code would fail the migration writer, but this is the
  user's responsibility and identical to the pre-existing `violation_error_message`
  assumption; adding a guard would be inconsistent. **No change** (documented only).

### D9 — Do not add a `get_violation_error_code()` getter
- Traces to: **SPEC C4**, **PV1**.
- `get_violation_error_message()` exists for `%(name)s` interpolation; the code needs
  none and is a passthrough, so no obligation calls for a getter. Adding unused
  surface is not justified by any finding. **No change.**

## Boundaries honestly recorded (not bugs)

- **PV3 / G4 — exception semantics:** the mini-X `raiseErr` abstracts Python
  exception propagation; the proof establishes the raised error's `code` binding, not
  end-to-end propagation through `full_clean()`/the DB layer (unchanged by the fix).
  Marked `[ESCALATION BOUNDARY]`, not faked as `[trusted]`.
- **Constructed, not machine-checked:** `kompile`/`kprove` were not run (no execution
  environment); the expected `#Top` outcome is reasoned in `PROOF.md §Reproduce`.
  Test-removal recommendations in `PROOF.md §9` are therefore conditioned on running
  those commands; the honest default is to keep all current tests.

## Artifacts produced

`fvk/constraints.k`, `fvk/constraints-spec.k`, `fvk/SPEC.md`, `fvk/FINDINGS.md`,
`fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`, `fvk/ITERATION_GUIDANCE.md`, and this
report. The V1 source fix (`reports/baseline_notes.md`) is unchanged.
