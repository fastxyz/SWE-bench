# ITERATION_GUIDANCE.md — django__django-15957

Feedback package for the next code/spec/intent pass. Each item: **evidence →
classification → UltimatePowers question → recommended change → tests.**

---

## Decision this pass: V1 stands (code unchanged)

The audit discharged the only bug-prone obligation — the off-by-one `(WSLICE)` (PO1/PO2/
PO3) — and the two control-flow obligations PO6/PO7, and routed the integration
obligations PO4/PO5 to the trusted base with spot-checks. **No finding rose to a code
bug in the supported domain**, so per the kit's rule ("if V1 is already correct according
to your spec and proof obligations, it may stand unchanged") the source is left as-is.
The justification is the artifact set, traced item-by-item in `reports/fvk_notes.md`.

---

## G1 — Off-by-one bounds — evidence PO1, `(WSLICE)`
- classification: **resolved / confirmed correct.**
- UltimatePowers question: none — the spec was clean and the closed form matches
  `len(rows[low:high])`.
- recommended change: none. Keep `> low` / `<= high`. Do **not** "tidy" to `>=`/`<` etc.
- tests: an explicit-offset case (`qs[1:3]`) and an offset-only case (`qs[2:]`) are the
  highest-value regressions; both are subsumed by the proof but cheap to keep.

## G2 — no-`to_attr` support via the `_filter_or_exclude` guard — evidence F3, PO6, PO7
- classification: **needed code change, justified and contained** (not a guard weakening
  in any user-facing path).
- UltimatePowers question: *"Should a sliced `Prefetch` without `to_attr` be supported, or
  required to use `to_attr`?"* V1 supports it (matches the general issue intent). If the
  product decision were "require `to_attr`", the alternative is to drop the guard change
  and raise instead — a one-line revert. Flagged so the intent owner can confirm.
- recommended change: keep. If ever reverted, also revert nothing else (the helper is
  independent and still fixes the `to_attr` case).
- tests: keep `test_slicing_cannot_filter_queryset_once_sliced` (eager guard) and a
  no-`to_attr` sliced-prefetch happy-path test as the two guard rails.

## G3 — unordered determinism — evidence Finding 3
- classification: **underspecified intent (docs), not a code bug.**
- UltimatePowers question: *"For example-rows without an explicit order, is DB-defined
  ordering acceptable, or should the API require/auto-apply an ordering?"*
- recommended change: documentation note ("add `order_by()` for deterministic rows"); no
  code change. Auto-injecting `pk` ordering would silently change result sets — rejected.
- tests: keep any test that pins ordered slices; none needed for the unordered case beyond
  documenting the non-guarantee.

## G4 — `low == 0` redundant lower bound — evidence Finding 4, PO0
- classification: **micro-optimization, declined.**
- recommended change: none. `if low_mark: predicate &= GreaterThan(...)` is
  behaviour-identical (proof shows size delta 0) and the QUALIFY rewrite dedupes the
  window; changing it would diverge from the established pattern for zero correctness gain.

## G5 — out-of-domain relations — evidence Findings 6–7, PO8/PO9
- classification: **scope boundary (escalation), not a bug.**
- UltimatePowers question: *"Should single-valued (forward-FK/O2O) or GenericRelation
  prefetches support slicing, or is raising acceptable?"*
- recommended change: none now. GenericRelation would need a composite
  `(content_type, object_id)` partition — a separate, larger change. Track as follow-up.
- tests: keep tests asserting these still raise (they pin the boundary).

## G6 — escalation boundary: the SQL/ORM trusted base — evidence PO4, PO5
- classification: **proof-capability gap (not a code bug).** The mini-X fragment models the
  slice arithmetic, not join construction, the QUALIFY rewrite, or ModelIterable column
  mapping. Fully verifying PO4/PO5 needs a real Django-ORM-in-K semantics (the kit's
  roadmap "full per-language semantics"), well beyond the bundled tier.
- recommended next step: **do not** fake these as `[trusted]` claims about correctness;
  they are argued + spot-checked here and routed to the trusted base. Keep the integration
  tests (m2m extra-select, join reuse) until that semantics exists and `kprove` closes them.

---

## If a future pass must change code
The helper `_filter_prefetch_queryset` is the single point of truth for the slice→window
rewrite; any change to the bounds must re-discharge `(WSLICE)`/`(WLOOP)` (re-run §6 of
`PROOF.md`). The guard change in `query.py` must preserve PO7's containment invariant
(keep the `grep` for `_defer_next_filter = True` at exactly the two `_apply_rel_filters`).
