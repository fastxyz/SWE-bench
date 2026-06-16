# Findings

Status: constructed, not machine-checked.

## F-1: V1 Rebound the Mapping Instead of Updating It In Place

Classification: public compatibility edge, resolved in V2.

Input/state:

- `LEVEL_TAGS` has been imported or referenced as a mapping object before
  `override_settings(MESSAGE_TAGS={50: 'critical'})`.
- The V1 receiver handles `setting_changed('MESSAGE_TAGS')`.

Observed under V1:

- `base.LEVEL_TAGS` is rebound to the new effective mapping.
- `Message.level_tag` reads the module global and is fixed.
- A pre-existing direct reference to the old mapping object remains stale.

Expected from the issue wording and compatibility audit:

- The stale `LEVEL_TAGS` state is refreshed for the module's observable and for
  the existing mapping object when practical.

Evidence:

- E1 names `LEVEL_TAGS` as the stale state.
- E9 identifies V1's rebinding behavior.
- PO-6 states the object-identity compatibility obligation.

Recommended change:

- Compute the new effective tags first, then `clear()` and `update()` the
  existing `LEVEL_TAGS` mapping.

Status:

- Applied in V2.

## F-2: Legacy Behavior Returned Empty String for In-Domain Custom Tags

Classification: code bug, resolved by V1 and preserved by V2.

Input/state:

- Before the fix, `LEVEL_TAGS` was initialized before
  `override_settings(MESSAGE_TAGS={50: 'critical'})`.
- A message with `level == 50` is read inside the override.

Observed before the fix:

- `Message.level_tag` looked up level `50` in stale `LEVEL_TAGS`.
- Since `50` was absent, it returned `''`.

Expected:

- `Message.level_tag` returns `'critical'`, because `MESSAGE_TAGS` extends
  defaults and includes level `50`.

Evidence:

- E2 reports the empty-string symptom.
- E4/E6 document custom level tags through `MESSAGE_TAGS`.
- PO-2 and PO-3 prove the receiver and lookup composition.

Recommended change:

- Keep the `setting_changed` receiver in `storage.base`.

Status:

- Confirmed in V2.

## F-3: Verification Is Constructed, Not Machine-Checked

Classification: proof capability gap.

Input/state:

- This workspace forbids running K tooling.

Observed:

- The `.k` semantics and claims are written, but `kompile`, `kast`, and
  `kprove` were not executed.

Expected:

- In a K-enabled environment, run the emitted commands and require `kprove` to
  return `#Top` before treating the proof as machine-verified or removing any
  tests.

Recommended next step:

- Keep or add tests until the K commands in `fvk/SPEC.md` and `fvk/PROOF.md`
  are run successfully.

Status:

- Open by environment constraint; not a code defect.

## Proof-derived Findings from `/verify`

No additional code bug was discovered after F-1 was resolved. The proof
obligations cover the complete intended behavior space for this issue:
override entry, override exit, custom levels, default fallback, missing-level
fallback, unrelated settings, and public API frame.

Test guidance:

- Add or keep a test for `override_settings(MESSAGE_TAGS={50: 'critical'})`
  where `Message(50, '...').level_tag == 'critical'`.
- Add or keep a restoration test proving the custom tag disappears after the
  override exits.
- Optionally add an internal compatibility test that an existing reference to
  `LEVEL_TAGS` observes the in-place refresh.
- Do not remove tests based on this constructed proof unless `kprove` returns
  `#Top`.
