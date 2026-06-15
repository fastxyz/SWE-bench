# FVK Notes

## Decision Summary

V1 stands unchanged. The FVK audit confirmed that the `Exists()`-based helper
implementation satisfies the public issue intent without reintroducing the
publicly rejected `DISTINCT` strategy.

## Source Code Decision

No source file was edited during the FVK pass.

Reasoning:

- `fvk/FINDINGS.md` F1 identifies the pre-V1 rendering bug as direct join
  filtering that can expand one target object into multiple option rows.
  `fvk/PROOF_OBLIGATIONS.md` PO-1 and PO-2 are discharged by V1 because the
  patched queryset uses a correlated `Exists()` predicate instead of joining the
  outer queryset to every witness row.
- `fvk/FINDINGS.md` F2 identifies the validation bug where `.get()` sees those
  duplicate rows. `fvk/PROOF_OBLIGATIONS.md` PO-3 is discharged because
  `ModelChoiceField.to_python()` uses the same queryset rewritten by the helper.
- `fvk/FINDINGS.md` F3 records the issue history rejecting row-wide
  `DISTINCT`. `fvk/PROOF_OBLIGATIONS.md` PO-4 is discharged because V1 adds
  `.filter(Exists(...))` and does not call `.distinct()`.
- `fvk/PROOF_OBLIGATIONS.md` PO-5 is discharged by the existing V1 conversion
  of dictionaries to `Q(**limit_choices_to)`, direct support for `Q` objects,
  callable resolution through `get_limit_choices_to()`, and no-op behavior for
  empty limits.
- `fvk/FINDINGS.md` F4 is a scope boundary, not a code defect: the public issue
  concerns duplicates introduced by `limit_choices_to`, not arbitrary custom
  querysets that are already duplicate before the helper runs.

## Artifact Decisions

I wrote the five required FVK artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also added `fvk/mini-django-queryset.k` and
`fvk/limit-choices-to-spec.k` because the FVK documentation requires a formal
core and exact future `kompile`/`kprove` commands. The K files are a compact
relational abstraction of the queryset cardinality property; they are not a full
Django ORM semantics. This limitation is recorded in `fvk/FINDINGS.md` F5 and
`fvk/PROOF_OBLIGATIONS.md` PO-6.

## Test and Tooling Decision

No tests, Python, or K commands were run, matching the task restrictions.

No test removal is recommended. `fvk/FINDINGS.md` F5 and
`fvk/PROOF_OBLIGATIONS.md` PO-6 require the proof to remain labeled
"constructed, not machine-checked" until a future environment runs the emitted
commands and receives `#Top`.
