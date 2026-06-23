# django__django-11551

## Summary

**Severity:** Low — baseline still validates `list_display` with the wrong
precedence, accepting an invalid `ManyToManyField` whenever a `ModelAdmin`
attribute happens to share the field's name; the trigger is a narrow name
collision, so the blast radius is small.

Both arms passed the official SWE-bench evaluation for issue #11551, with
**different** patches. Baseline fixed the reported descriptor-`AttributeError`
false positive but kept checking `ModelAdmin` attributes *before* same-named
model fields; FVK reordered the check so model-metadata lookup runs first, matching
Django's documented `lookup_field()` interpretation order. The defect is minor;
the case is about FVK locating a residual ordering gap by **formalizing the
documented precedence as an obligation and auditing the V1 branch order against
it** — not by running a new test.

| Arm | `list_display` precedence (M2M field vs same-named admin attr) | Resolved |
|---|---|---|
| baseline | wrong order — admin attribute short-circuits, M2M not rejected | no |
| gold (human oracle) | field-first order | yes |
| **fvk** | field-first order (`_meta.get_field` before `hasattr(obj, item)`) | **yes** |

## 1. The issue and the real defect

**Issue #11551** — `ModelAdminChecks._check_list_display_item()` raises
`admin.E108` for a `list_display` entry that names a real model field, when that
field's class-level descriptor raises `AttributeError` on access even though the
field is present in model metadata
([`prompts/fvk.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/prompts/fvk.md#L1)).
The user-facing observable: a valid admin configuration is rejected at startup.

The original `_check_list_display_item()` consulted the model class before the
metadata table:

```python
elif hasattr(obj, item):
    return []
elif hasattr(obj.model, item):
    try:
        field = obj.model._meta.get_field(item)
    ...
```

Because `hasattr(obj.model, item)` returns `False` when the descriptor raises,
the metadata lookup was skipped entirely and the item was reported as `E108`.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/solutions/solution_baseline.patch)
restructured the helper to try `obj.model._meta.get_field(item)` first and fall
back to `getattr(obj.model, item)`, so a metadata-visible field is no longer
rejected for a failing descriptor, and the `ManyToManyField` check runs after
resolution on either path. Its reasoning was sound for the reported bug:

> *"`ModelAdminChecks._check_list_display_item()` checked `hasattr(obj.model,
> item)` before attempting `obj.model._meta.get_field(item)` … the metadata
> lookup was skipped, and admin validation incorrectly reported `admin.E108`."*
> — [`reports/baseline_notes.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/reports/baseline_notes.md#L5)

But the baseline patch retained the leading guard
`elif hasattr(obj, item): return []`
([`solution_baseline.patch`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/solutions/solution_baseline.patch#L7))
**ahead of** the new metadata lookup. So when a `ModelAdmin` defines an
attribute or method whose name collides with a model field, the helper returns
`OK` from the admin guard before it ever consults `_meta.get_field()`. If that
same-named model field is a `ManyToManyField`, the documented `admin.E109`
rejection is silently skipped. Baseline fixed the descriptor case but left the
documented field-before-admin precedence unmet.

## 3. How FVK formally captured the gap

FVK started from documented intent, not the symptom. The decisive intent item
states the precedence directly:

> **Intent 6:** *"Model fields have precedence over same-named `ModelAdmin`
> attributes for interpretation and validation."*
> — [`fvk/INTENT_SPEC.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/fvk/INTENT_SPEC.md#L15)

The evidence ledger pins that intent to two concrete, source-audited facts — the
admin docs and the runtime resolver — **not** to any reported test:

> **E6:** *"interpret every element … in this order: A field of the model. A
> callable. … `ModelAdmin` … model attribute."* → *Model field metadata lookup
> has precedence over same-named admin/model fallback.*
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/fvk/PUBLIC_EVIDENCE_LEDGER.md#L10)

> **E8:** *`lookup_field()` calls `_get_non_gfk_field()` before callable/admin/
> model attribute fallback.* → *Validation should be compatible with runtime
> field-first interpretation.*
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/fvk/PUBLIC_EVIDENCE_LEDGER.md#L12)

Those discharge into a precedence-bearing obligation:

> **PO3 — Metadata `ManyToManyField` rejection and precedence:** *if
> `callable(item) == false` and metadata lookup resolves a `ManyToManyField`,
> the result is `E109`, **even when a same-named `ModelAdmin` attribute
> exists**.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/fvk/PROOF_OBLIGATIONS.md#L18)

This is the crux: the precedence defect was located by **reasoning against the
documented order**, not by observation. The issue is about a descriptor false
positive; FVK lifts the docs' interpretation order into an obligation over the
branch structure, and PO3 is the obligation the baseline branch order violates.

## 4. From formal output to the fix

Auditing the V1 branch order against PO3 surfaced the residual finding:

> **F2. V1 still allowed a `ModelAdmin` attribute to mask a same-named model
> field for validation.** *Observed in V1: `OK`, because V1 returned immediately
> for `hasattr(obj, item)` before field metadata lookup. Expected: `E109` …
> Proof obligations: PO3, PO9. Status: resolved in V2 by moving metadata lookup
> before `hasattr(obj, item)`.*
> — [`fvk/FINDINGS.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/fvk/FINDINGS.md#L19)

The iteration guidance turned the finding into the concrete reorder:

> *"V2 keeps the V1 fix for Finding F1 and adds the field-first validation order
> required by PO3"* — *"Resolve model fields through `_meta.get_field(item)`"*
> before admin/model fallback.
> — [`fvk/ITERATION_GUIDANCE.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/fvk/ITERATION_GUIDANCE.md#L11)

The decision log records the source change and its provenance:

> *"V1 … still checked `ModelAdmin` attributes before same-named model fields …
> so V2 moves `_meta.get_field(item)` before `hasattr(obj, item)`."* — *"Finding
> F2 and PO3 justify the V2 improvement."*
> — [`reports/fvk_notes.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/reports/fvk_notes.md#L9)

The causal chain is fully on the record:

```
INTENT 6 (field precedence)  ->  E6 / E8 (docs + lookup_field() audit)
                             ->  PO3 (M2M rejection even with same-name admin attr)
                             ->  F2  (V1 admin guard masks the field)
                             ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 reorder
```

The resulting [V2 patch](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/solutions/solution_fvk.patch)
drops the leading admin guard and runs `_meta.get_field()` first, demoting the
`hasattr(obj, item)` acceptance into the `FieldDoesNotExist` branch:

```python
try:
    field = obj.model._meta.get_field(item)
except FieldDoesNotExist:
    if hasattr(obj, item):
        return []
    ...
```

([`solution_fvk.patch`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/solutions/solution_fvk.patch#L25)).
The `V1 -> V2` change was driven by `F2`/`PO3`, **not** by a new failing test —
no test for the same-name collision exists in the audited input (the prompt
forbids editing or inferring tests, see §5).

## 5. Verification

**Source-and-artifact reviewed; not executed.** This is a Tier-3 case: no harness
proof reports exist for this instance and the FVK run carried out no executed
demonstration (the prompt explicitly forbids running tests, Python, or K
tooling —
[`prompts/fvk.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/prompts/fvk.md#L26)).
What was inspected:

- The two patch hunks, confirming the byte-level reorder of
  `hasattr(obj, item)` relative to `_meta.get_field(item)`
  ([baseline](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/solutions/solution_baseline.patch#L7),
  [fvk](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/solutions/solution_fvk.patch#L25)).
- The finding-to-fix trace across
  [`FINDINGS.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/fvk/FINDINGS.md#L19),
  [`PROOF_OBLIGATIONS.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/fvk/PROOF_OBLIGATIONS.md#L18),
  [`ITERATION_GUIDANCE.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/fvk/ITERATION_GUIDANCE.md#L11),
  and
  [`fvk_notes.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/reports/fvk_notes.md#L9).
- The constructed K spec
  ([`list-display-check-spec.k`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/fvk/list-display-check-spec.k),
  [`mini-admin-check.k`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/fvk/mini-admin-check.k)),
  whose claims mirror the obligations but were not machine-checked.

**Gold comparison.** The human oracle for #11551 also reorders the helper to run
the model-field lookup before the admin-attribute fallback, the same field-first
order FVK arrived at; the FVK patch is consistent with that resolution rather than
exceeding it. (No gold patch artifact is retained for this instance, so this
comparison is from the documented resolution behavior, not a side-by-side diff.)

## 6. Boundaries & honesty

- **Severity: Low.** The residual defect only triggers on a same-name collision
  between a `ModelAdmin` attribute/method and a model field — and only matters
  when that field is a `ManyToManyField` (the case PO3 governs). That conjunction
  is uncommon in real admin configs, so the practical blast radius is small. The
  value here is **detection of a documented-precedence gap**, not impact
  magnitude.
- **Proof status: constructed, not machine-checked.** The K artifacts and the
  `kompile`/`kast`/`kprove` commands were written but never run — the FVK
  artifacts state this explicitly
  ([`fvk/PROOF.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/fvk/PROOF.md#L3),
  [F5](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/fvk/FINDINGS.md#L54)).
  We claim **proof-structured reasoning**, not a verified proof.
- **Attribution.** With no harness report or executed demonstration for this
  instance, the correctness of the reorder is supported by the documented
  precedence and the on-record `F2 -> PO3 -> V2` trace, not by an observed
  RED→GREEN. The `V1 -> V2` ordering can be timestamped from
  [`transcripts/fvk.jsonl.gz`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/transcripts/fvk.jsonl.gz)
  if a reviewer wants the raw trace.

## Artifact map

| Claim | Source |
|---|---|
| Issue / task statement | [`prompts/fvk.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/prompts/fvk.md#L1) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/solutions/solution_baseline.patch#L7) |
| Baseline reasoning | [`reports/baseline_notes.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/reports/baseline_notes.md#L5) |
| FVK patch | [`solutions/solution_fvk.patch`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/solutions/solution_fvk.patch#L25) |
| Intent: field precedence | [`fvk/INTENT_SPEC.md#L15`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/fvk/INTENT_SPEC.md#L15) |
| Evidence E6 (docs order) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md#L10`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/fvk/PUBLIC_EVIDENCE_LEDGER.md#L10) |
| Evidence E8 (`lookup_field`) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md#L12`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/fvk/PUBLIC_EVIDENCE_LEDGER.md#L12) |
| Obligation PO3 | [`fvk/PROOF_OBLIGATIONS.md#L18`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/fvk/PROOF_OBLIGATIONS.md#L18) |
| Finding F2 | [`fvk/FINDINGS.md#L19`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/fvk/FINDINGS.md#L19) |
| Iteration guidance (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L11`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/fvk/ITERATION_GUIDANCE.md#L11) |
| Decision trace | [`reports/fvk_notes.md#L9`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/reports/fvk_notes.md#L9) |
| Proof status caveat | [`fvk/PROOF.md#L3`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/fvk/PROOF.md#L3), [`fvk/FINDINGS.md#L54`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/fvk/FINDINGS.md#L54) |
| Constructed K spec | [`fvk/list-display-check-spec.k`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/fvk/list-display-check-spec.k), [`fvk/mini-admin-check.k`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/fvk/mini-admin-check.k) |
| Raw model traces | [`transcripts/fvk.jsonl.gz`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11551/transcripts/fvk.jsonl.gz) |
