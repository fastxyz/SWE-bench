# ITERATION_GUIDANCE.md — django__django-14631

Feedback package for the next generate→formalize→verify pass. Each item: evidence,
classification, the UltimatePowers question for the user, the recommended code/spec
change, and tests.

## Verdict

**V1 is CONFIRMED and STANDS** (plus one inert clarifying comment added this pass).
The FVK audit found **no correctness defect** in V1: the core fix is proved
(`PROOF.md` §3, claims `(CLEAN-DISABLED-CONSISTENCY)`+`(BF-INIT-HIT)`), and every other
path is shown behavior-preserving by definitional equality and symbolic execution
(`PROOF_OBLIGATIONS.md` B–D). The single change applied this pass is a two-line comment
in `_clean_fields` encoding the PO-CLEAN-CONSIST invariant — no behavior change.

## UP-1 — Confirm the intended behavior change for disabled datetime/time fields
- **Evidence:** F2; `BoundField.initial` strips microseconds (`#22502`) so V1's
  `cleaned_data[name]` for a disabled `DateTimeField`/`TimeField` now equals the nixed
  `form[name].initial` (V0 kept microseconds).
- **Classification:** intended behavior change / test-expectation update.
- **UltimatePowers question:** "For a disabled datetime/time field, should
  `cleaned_data` match the rendered/`initial` value (microseconds normalized) — yes per
  this ticket — or retain full microseconds?" The ticket answers *match initial*.
- **Recommended change:** none to code; ensure the test asserting the old
  microsecond-preserving value is the *adjusted* `cleaned_value == bf.initial` form
  (the ticket explicitly sanctions this). Tests are hidden here — do not edit.
- **Tests:** keep the adjusted `test_datetime_clean_initial_callable_disabled`; it is
  subsumed by the proof once machine-checked.

## UP-2 — Private helper name: `_has_changed` vs the sketch's `_did_change`
- **Evidence:** F4. Ticket prose: "could be called *something like* `bf.did_change()`";
  code sketch: `bf._did_change()`. V1 uses `_has_changed`.
- **Classification:** cosmetic / naming; behavior-neutral (no PO depends on it).
- **UltimatePowers question:** "Must the private method name match the sketch
  (`_did_change`), or is a name aligned with `Field.has_changed` (`_has_changed`)
  preferred?"
- **Recommended change:** keep `_has_changed` (mirrors the delegated
  `Field.has_changed`); if strict fidelity is required, mechanically rename the two
  occurrences (`forms.py` `changed_data`, `boundfield.py` method def).
- **Tests:** none — private method, exercised only via `changed_data`/`has_changed`.

## UP-3 — Document/optionally enforce the `bf.field is self.fields[name]` assumption
- **Evidence:** F5 / PO-FIELD-ID. V1 reads `field = bf.field`. Holds for core Django;
  a third-party `get_bound_field` wrapping a different field would break the refinement.
- **Classification:** documented assumption / robustness.
- **UltimatePowers question:** "Is a custom `Field.get_bound_field` allowed to return a
  BoundField wrapping a field other than `self`? If so, should `_clean_fields` trust
  `bf.field` or re-fetch `self.fields[name]`?"
- **Recommended change:** none required (the BoundField contract is "a Field plus
  data," and V0 already routed `initial` through `get_bound_field`). If maximal caution
  is wanted, a one-line release note that `_clean_fields`/`changed_data` now read the
  field via the BoundField.
- **Tests:** existing BoundField/get_bound_field tests already pin the contract.

## UP-4 — Concretize the `_has_changed` abstraction for full machine-checking
- **Evidence:** F7; the fragment abstracts `Field.has_changed` (None/'' folding,
  `MultiValueField`/`JSONField` overrides) into `hcPred(N)` and the show-hidden branch
  into `hiddenVal`/`verr`.
- **Classification:** proof-capability gap (not a code bug).
- **Recommended next spec change:** to lift the refinement proof from "constructed" to
  "machine-checked," expand `mini-forms.k` with concrete `has_changed` rules per field
  subclass, or prove the generic `field.has_changed(equal-args)` congruence once and
  reuse. Out of scope for this fix (V0 and V1 call the *same* `has_changed` with equal
  args, so the refactor is safe regardless).
- **Tests:** keep the `show_hidden_initial` and field-specific `has_changed` tests.

## Carry-forward summary
- No bug to fix in V1. ✅
- One inert comment added (traceable to PO-CLEAN-CONSIST / F1).
- Open *questions* (UP-1..UP-4) are confirmations and documentation, not defects.
- Machine-check path: run the `kompile`/`kprove` commands in `PROOF.md` §6 to reach
  `#Top`; only then act on the test-redundancy recommendation (and never on hidden
  tests).
