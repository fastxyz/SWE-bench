# django__django-11095

## Summary

**Severity:** Medium — baseline routes admin related-object validation through an
objectless dynamic `get_inlines()` hook, so a valid `to_field` related-object path
can be rejected when the hook depends on the edited object.

The issue asked for an additive `ModelAdmin.get_inlines(request, obj)` hook. Baseline
implemented it correctly for inline *display*, but also rewired the unrelated
`BaseModelAdmin.to_field_allowed()` to call `admin.get_inlines(request)` with no
object — letting object-dependent display logic mutate the static validation
registry. FVK located this by formalizing a frame condition (related-object
validation stays on static `admin.inlines`) and reverted only that edit.

| Arm | `to_field_allowed()` registry source | Resolved |
|---|---|---|
| baseline | `admin.get_inlines(request)` (objectless dynamic hook) | no |
| gold (human oracle) | static `admin.inlines` (never touched) | yes |
| **fvk** | reverted to static `admin.inlines` | yes |

## 1. The issue and the real defect

The issue: "add `ModelAdmin.get_inlines()` hook to allow set inlines based on the
request or model instance"
([`fvk/PUBLIC_EVIDENCE_LEDGER.md` E-001](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11095/fvk/PUBLIC_EVIDENCE_LEDGER.md#L5)).
The intended change is additive and localized: `get_inline_instances()` should call a
new hook, while the existing static behavior remains the default. `to_field_allowed()`
is a *separate* path — it participates in related-object raw-id / `to_field` validation
and has no edited-object context to pass.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11095/solutions/solution_baseline.patch)
added the hook and made `get_inline_instances()` delegate to it — the correct core.
But it also changed `to_field_allowed()`, and its notes show this was a *deliberate*
choice it believed was a consistency improvement:

> *Updated `BaseModelAdmin.to_field_allowed()` to consult `admin.get_inlines(request)`*
> *when gathering registered inline models. This keeps related-object validation*
> *consistent with inline classes supplied by [the hook].*
> — [`reports/baseline_notes.md`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11095/reports/baseline_notes.md#L22)

The unmet obligation: `admin.get_inlines(request)` passes `obj=None`. A hook that
returns `[]` for the objectless / add-view state then drops that inline's model from
the registry used by `to_field_allowed()`, so a valid related-object path is rejected
even though the static admin registration still includes the inline. Baseline stopped
one step short of seeing that the display hook must not mutate a static validation
registry.

## 3. How FVK formally captured the gap

The intent spec separates the dynamic display path from the static validation path
explicitly — a frame condition written from public intent, not from a test:

> **I-005:** *Existing related-object validation behavior should not be changed by the*
> *[hook]. … public docs … identify `inlines` as the static registry.*
> — [`fvk/INTENT_SPEC.md`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11095/fvk/INTENT_SPEC.md#L43)

The evidence ledger pins that to the public-docs fact found by audit — the "Bad
Request" warning that ties related-object validation to the static `inlines`:

> **E-005:** *do not accidentally change the related-object validation registry from*
> *static `inlines` to an objectless dynamic hook call.*
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11095/fvk/PUBLIC_EVIDENCE_LEDGER.md#L59)

Which becomes a formal frame claim and its obligation:

> **Claim TO-FIELD-ALLOWED-FRAME:** *The related-object validation registry used by*
> *`to_field_allowed()` remains based on static `admin.inlines`; it is not affected by*
> *the new dynamic hook.*
> — [`fvk/FORMAL_SPEC_ENGLISH.md`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11095/fvk/FORMAL_SPEC_ENGLISH.md#L26)

> **PO-004 — Related-object validation frame condition.** *`to_field_allowed()` must*
> *continue to collect inline models from static `admin.inlines`.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11095/fvk/PROOF_OBLIGATIONS.md#L43)

The defect was located by reasoning: the hook is request/object dependent by design,
so any code that consumes it without an object — like `to_field_allowed()` — silently
breaks the static frame, independent of any test.

## 4. From formal output to the fix

The audit against the frame condition produced the primary finding:

> **F-001: V1 changed related-object validation through an objectless hook call.**
> *`to_field_allowed(...)` gathered inline models from `admin.get_inlines(request)`,*
> *which passes no object … This path should continue to use `admin.inlines`.*
> — [`fvk/FINDINGS.md`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11095/fvk/FINDINGS.md#L5)

The iteration guidance turned it into the exact code action — keep the hook, revert
only `to_field_allowed()`:

> *Restore `to_field_allowed()` to iterate over static `admin.inlines`. This resolves*
> *Finding F-001 and discharges PO-004.*
> — [`fvk/ITERATION_GUIDANCE.md`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11095/fvk/ITERATION_GUIDANCE.md#L13)

And the decision trace records the revert and its provenance:

> *V2 changes V1 by reverting the `BaseModelAdmin.to_field_allowed()` edit. Trace:*
> *F-001 showed that V1 called `admin.get_inlines(request)` in a path with no `obj`*
> *context … PO-004 therefore requires `to_field_allowed()` to keep using static*
> *`admin.inlines`.*
> — [`reports/fvk_notes.md`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11095/reports/fvk_notes.md#L5)

```
I-005  ->  E-005 (audit: docs tie related-object validation to static inlines)
       ->  TO-FIELD-ALLOWED-FRAME / PO-004
       ->  F-001 (V1 audit: to_field_allowed() uses objectless get_inlines)
       ->  ITERATION_GUIDANCE / fvk_notes  ->  revert to_field_allowed() to admin.inlines
```

The [FVK patch](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11095/solutions/solution_fvk.patch)
keeps the hook and `get_inline_instances()` delegation but restores the static scan:

```python
for inline in admin.inlines:
    registered_models.add(inline.model)
```

The revert was driven by the formal frame finding F-001 / obligation PO-004, **not**
by a new failing test — the official FAIL_TO_PASS test exercises only the display
hook.

## 5. Verification

**Source-and-artifact reviewed; not executed.** Not on the harness (`proof=no`), not
curated — no RED/GREEN report, no executed demonstration. What was inspected:

- The FVK patch vs baseline patch (`diff`): the *only* difference is that the FVK arm
  drops baseline's `to_field_allowed()` change (`admin.inlines` →
  `admin.get_inlines(request)`); the hook and delegation are unchanged.
- F-001 / PO-004 / TO-FIELD-ALLOWED-FRAME: the rejection scenario (a hook returning
  `[]` for the objectless state drops an inline's model from the validation registry)
  is argued as static reasoning, not run here.

**Gold comparison (no gold file in this non-curated run).** The official gold fix adds
`get_inlines()` and changes `get_inline_instances()` only; it does **not** modify
`to_field_allowed()`. FVK restores exactly that boundary baseline crossed — so FVK is
not a stylistic alternative; it removes a baseline-only behavioral regression the
official fix never introduced. Both arms passed the official SWE-bench evaluation.

## 6. Boundaries & honesty

- **Severity: Medium.** The trigger is narrower than always-on: it needs a
  `get_inlines()` override that returns fewer inlines for the objectless / add-view
  state *and* a related-object `to_field` validation against one of the dropped
  inlines' models. It is a silent wrong rejection (a valid path treated as
  disallowed), not an exception — real, but gated on a specific admin configuration,
  hence Medium rather than High.
- **Evidence is static.** The regression claim rests on reading the patch delta, the
  frame obligation, and F-001's case analysis; no admin scenario was executed here.
- **Why the tests missed it.** The FAIL_TO_PASS test exercises
  `get_inline_instances()` only; it never combines an object-dependent `get_inlines()`
  override with the `to_field_allowed()` path, so both arms pass.
- **Proof status: constructed, not machine-checked.** No `kompile`/`kprove` were run
  ([`fvk/PROOF.md`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11095/fvk/PROOF.md#L3)).
  Cited as proof-structured reasoning; the gold patch independently corroborates the
  boundary.

## Artifact map

| Claim | Source |
|---|---|
| Issue (add `get_inlines` hook) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md#L5`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11095/fvk/PUBLIC_EVIDENCE_LEDGER.md#L5) |
| Baseline changed `to_field_allowed()` deliberately | [`reports/baseline_notes.md#L22`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11095/reports/baseline_notes.md#L22) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11095/solutions/solution_baseline.patch) |
| Intent I-005 (validation frame) | [`fvk/INTENT_SPEC.md#L43`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11095/fvk/INTENT_SPEC.md#L43) |
| Evidence E-005 (docs audit) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md#L59`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11095/fvk/PUBLIC_EVIDENCE_LEDGER.md#L59) |
| Frame claim TO-FIELD-ALLOWED-FRAME | [`fvk/FORMAL_SPEC_ENGLISH.md#L26`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11095/fvk/FORMAL_SPEC_ENGLISH.md#L26) |
| Obligation PO-004 | [`fvk/PROOF_OBLIGATIONS.md#L43`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11095/fvk/PROOF_OBLIGATIONS.md#L43) |
| Finding F-001 | [`fvk/FINDINGS.md#L5`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11095/fvk/FINDINGS.md#L5) |
| Iteration instruction (revert) | [`fvk/ITERATION_GUIDANCE.md#L13`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11095/fvk/ITERATION_GUIDANCE.md#L13) |
| Decision trace (V2 revert) | [`reports/fvk_notes.md#L5`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11095/reports/fvk_notes.md#L5) |
| FVK patch | [`solutions/solution_fvk.patch`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11095/solutions/solution_fvk.patch) |
| Proof not machine-checked | [`fvk/PROOF.md#L3`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11095/fvk/PROOF.md#L3) |
