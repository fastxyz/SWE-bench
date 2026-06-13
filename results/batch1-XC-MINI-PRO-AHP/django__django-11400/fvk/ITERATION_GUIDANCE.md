# ITERATION_GUIDANCE.md — django__django-11400

Feedback package from `/formalize` + `/verify` for the next code/spec iteration.
**Headline: V1 stands. No code change is required by the audit.** Every correctness
proof obligation (PO1–PO7) is discharged by construction and every trusted-base
obligation (PO8–PO12) by source citation; the audit surfaced **no correctness defect in
the V1 fix**. The items below are the residual, the rejected alternatives, and the
questions a deeper pass could ask.

## 1. Verdict and its justification

- **(GC-META)/(FC-META-*)** prove the fix achieves the issue's primary ask:
  `RelatedFieldListFilter` now falls back to `Meta.ordering` (`FINDINGS.md` F1, `PROOF.md` §1).
- **(FC-ADMIN)** + PO6 prove `RelatedOnlyFieldListFilter` now orders at all and honors
  admin ordering (`FINDINGS.md` F2, `PROOF.md` §5).
- **(BUG-OLD)** proves the fix is load-bearing — the old code provably violated
  (GC-META) (`PROOF.md` §2).
- F3/PO11 confirm the fix orders the *correct* model; F4/PO12 confirm no collateral
  behavior change; F6/F7/PO13/PO14 confirm no truthiness or "invented ordering" regressions.

Because the conclusion "V1 is correct" is itself derived from the artifacts, V1 is kept
**unchanged** (the task permits a correct V1 to stand). See `reports/fvk_notes.md`.

## 2. Residual risk to carry forward (not defects)

| Risk | Where | Recommended next action |
|------|-------|-------------------------|
| Trusted base: `mini_orm.k` faithfulness to `query.py`/`compiler.py` | `SPEC.md §4`, PO8/PO9 | machine-check by running `kompile`/`kprove`; or add an integration test that asserts the emitted SQL ORDER BY for an admin-less, `Meta.ordering`-only related model |
| Partial correctness (termination of the comprehension) | PO15 | none needed — DB querysets are finite; flag only if `get_choices` ever wraps an infinite iterator |
| Behavior change for hypothetical *external* callers of `Field.get_choices()` on relational fields | F4 | document in the release notes that relational `get_choices()` now respects `Meta.ordering` for empty `ordering` (this is the intended, more-correct behavior) |

## 3. Out-of-scope item recorded for a future decision (NOT fixed here)

- **F5 / PO16 — `RelatedOnlyFieldListFilter` on reverse relations** raises `TypeError`
  because `ForeignObjectRel.get_choices` has no `limit_choices_to` parameter.
  - **Classification:** pre-existing latent bug, untouched by this issue's fix.
  - **UltimatePowers question to the user:** *"Should `RelatedOnlyFieldListFilter`
    support reverse relations? If so, `ForeignObjectRel.get_choices` needs a
    `limit_choices_to` parameter (and a `complex_filter` on the reverse manager)."*
  - **Recommended next code change (only if desired):** add `limit_choices_to=None` to
    `ForeignObjectRel.get_choices` mirroring `Field.get_choices`, then this filter would
    work for reverse relations too. **Deliberately deferred** to keep the fix minimal and
    on-issue.

## 4. Rejected alternative implementations (and why V1's is preferred)

- **Alt-A: fall back in `filters.py`** by passing
  `field.remote_field.model._meta.ordering` when the admin ordering is empty, leaving
  `get_choices` calling `order_by(*ordering)` unconditionally.
  *Rejected:* would have to be duplicated for forward and reverse `get_choices`, and
  re-introduces the bare-`order_by()` trap whenever *both* admin ordering and
  `Meta.ordering` are empty (it would emit `order_by()` and disable any future default).
  V1's `if ordering:` guard fixes the root cause once, where it lives.
- **Alt-B: change `Query.add_ordering`** so empty args no longer set
  `default_ordering = False`. *Rejected:* shared global query machinery; other code
  relies on `.order_by()` clearing ordering — broad regression risk far outside the issue.
- **Alt-C: fix only `RelatedOnlyFieldListFilter`.** *Rejected:* the issue reports two
  defects (F1 + F2); (GC-META) shows `RelatedFieldListFilter` also needed the
  `get_choices` change.

## 5. Tests to add/keep (detail in `PROOF.md §8`)

- **Add (if absent):** the four ordering assertions enumerated in `PROOF.md §8`
  (Meta-ordering fallback and admin-ordering, for each of the two filters on forward
  relations).
- **Keep:** integration/changelist tests, reverse-relation `RelatedOnly` behavior,
  `get_choices` on choices-declared fields, termination/performance.
- **Conditionally remove (only after `kprove` ⇒ `#Top`):** unit tests that merely
  re-assert a single in-domain ordering point already entailed by the contracts.
  Per the Honesty gate, **keep them until the machine check passes**.
