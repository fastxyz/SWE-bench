# django__django-14725

## Summary

**Severity:** Low — baseline can silently create records despite an edit-only save contract,
but only when application code overrides the semi-private `save_new_objects()` hook without
calling `super()`.

Baseline and FVK both passed the official SWE-bench evaluation for the "edit-only model
formset" feature, but baseline put the `edit_only` guard *only* in the semi-private
`save_new_objects()` helper. Because `save()` reaches that helper through virtual dispatch,
a formset subclass that overrides it still creates new objects despite `edit_only=True`. FVK
moved the guard up into `save()` (exactly where gold put it), closing the hole. FVK located
the gap by **formalizing the public `save()` entry point as the obligation site and noting it
virtually dispatches to an overrideable creation path**, not by running more tests.

| Arm | custom `save_new_objects()` override + `edit_only=True`, `Author.objects.count()` | Resolved |
|---|---|---|
| baseline | **2** — records created, contract violated | no |
| gold (human oracle) | 0 | yes |
| **fvk** | 0 | **yes** |

(No harness `_proof` exists for this instance; verification is an executed demonstration on
three built trees — see §5.)

## 1. The issue and the real defect

The issue — *"Provide a way for model formsets to disallow new object creation"*: model
formsets have no reliable "edit only" mode. `extra=0` is only a *display* hint — a client can
add forms via JavaScript or by editing the management-form `TOTAL_FORMS`/`INITIAL_FORMS`
counts and POST extra rows, which the server turns into new objects
([`problem_statement.md`](../verified500_analysis/django__django-14725/_materials/problem_statement.md#L1)).
The ticket asks for an explicit opt-in (`edit_only=True`) that disallows new object creation
while still saving edits to existing objects.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified017-codex-XC-MINI-PRO-AHP-20260616T052940Z/django__django-14725/solutions/solution_baseline.patch)
added `edit_only` and threaded it through `modelformset_factory`, `inlineformset_factory`,
and `generic_inlineformset_factory` (identical to fvk and gold). For enforcement, baseline
guarded **only** `save_new_objects()`:

```python
def save_new_objects(self, commit=True):
    self.new_objects = []
    if self.edit_only:          # guard here ONLY
        return self.new_objects
    ...
def save(self, commit=True):
    ...
    return self.save_existing_objects(commit) + self.save_new_objects(commit)  # virtual dispatch
```

Baseline's notes show it explicitly *considered* guarding `save()` and chose the helper
instead:

> *"I also considered only changing `save()` to skip `save_new_objects()` when edit-only
> mode is enabled. I kept the guard inside `save_new_objects()` instead so direct callers of
> that method get the same protection …"*
> — [`reports/baseline_notes.md`](../results/verified017-codex-XC-MINI-PRO-AHP-20260616T052940Z/django__django-14725/reports/baseline_notes.md#L38)

That reasoning is half right — direct callers *should* be protected — but it picked the
helper as the *only* site. Because `save()` calls `self.save_new_objects(commit)`
*virtually*, a subclass that overrides `save_new_objects()` without `super()` bypasses the
guard. The obligation baseline left unmet: **the public `save()` entry point must be safe
against virtual dispatch to an overrideable creation path.**

## 3. How FVK formally captured the gap

FVK started from an intent spec that names the compatibility/dispatch concern, not just the
feature:

> *"I-7. Existing public callsites must remain compatible. Adding a keyword must not break
> existing positional or keyword calls, and the edit-only guard must not depend on
> un-audited virtual dispatch when a public customization point exists."*
> — [`fvk/SPEC.md`](../results/verified017-codex-XC-MINI-PRO-AHP-20260616T052940Z/django__django-14725/fvk/SPEC.md#L48)

The evidence ledger pins that intent to a concrete implementation fact: `formset=` lets
callers supply subclasses, and `save()` dispatches on `self` —

> **E-7.** *`modelformset_factory()` accepts a custom `formset` class, and `save()`
> dispatches methods on `self`. Obligation: the primary edit-only guard belongs in `save()`
> before virtual dispatch to `save_new_objects()`. Status: V2 code change; see Finding F-2
> and PO-7.*
> — [`fvk/SPEC.md`](../results/verified017-codex-XC-MINI-PRO-AHP-20260616T052940Z/django__django-14725/fvk/SPEC.md#L83)

This discharges into a formal obligation:

> **PO-7: Virtual-dispatch safety at the public `save()` entry point.** *Edit-only behavior
> must not rely solely on the base implementation of a method that is reached by virtual
> dispatch from `save()`. … Discharge status: satisfied by V2. The primary edit-only guard
> is in `BaseModelFormSet.save()` before `self.save_new_objects(commit)` can be called.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified017-codex-XC-MINI-PRO-AHP-20260616T052940Z/django__django-14725/fvk/PROOF_OBLIGATIONS.md#L69)

This is the crux: the gap was located by **reasoning about virtual dispatch**, not by
observing a failing test. The intent (I-7) says the guard must not depend on un-audited
virtual dispatch when a public customization point exists; E-7 establishes `formset=` as
exactly such a point and `save()`'s call as virtual; therefore the guard must sit in `save()`
before the dispatch. Baseline's helper-only guard is the violation.

## 4. From formal output to the fix

The repair is iterative, and the artifacts record the step where the formalism changed the
patch.

- **V1** guarded only `save_new_objects()` (identical to what baseline shipped).
- The completeness audit against the spec raised a finding:

  > **F-2: V1 virtual-dispatch gap.** *Input: a formset class created with `edit_only=True`
  > using a custom formset subclass that overrides `save_new_objects()` and does not call
  > `super()`. Observed in V1 by static dispatch reasoning: `BaseModelFormSet.save()` still
  > called `self.save_new_objects(commit)`, so the override could create new objects despite
  > edit-only mode.*
  > — [`fvk/FINDINGS.md`](../results/verified017-codex-XC-MINI-PRO-AHP-20260616T052940Z/django__django-14725/fvk/FINDINGS.md#L27)

- The iteration guidance turned the finding into the code decision:

  > *"Apply Finding F-2 and proof obligation PO-7 by enforcing edit-only mode in
  > `BaseModelFormSet.save()` before virtual dispatch to `save_new_objects()`."*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified017-codex-XC-MINI-PRO-AHP-20260616T052940Z/django__django-14725/fvk/ITERATION_GUIDANCE.md#L7)

- The decision log records the change and its provenance:

  > *"I changed `repo/django/forms/models.py` after the FVK audit found V1's guard was too
  > low in the dispatch stack. … V2 now checks `self.edit_only` inside `save()`, initializes
  > `self.new_objects = []`, and returns `save_existing_objects(commit)` before
  > `save_new_objects()` can be called."*
  > — [`reports/fvk_notes.md`](../results/verified017-codex-XC-MINI-PRO-AHP-20260616T052940Z/django__django-14725/reports/fvk_notes.md#L3)

The causal chain is fully on the record:

```
SPEC I-7  ->  E-7 (formset= is a public customization point; save() dispatches virtually)
          ->  F-2 (V1 audit: helper-only guard bypassed by override)
          ->  PO-7 (obligation: guard save() before virtual dispatch)
          ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 patch
```

The
[V2 patch](../results/verified017-codex-XC-MINI-PRO-AHP-20260616T052940Z/django__django-14725/solutions/solution_fvk.patch)
adds the guard inside `save()`, short-circuiting before the virtual dispatch (keeping
baseline's helper guard as belt-and-suspenders):

```python
if self.edit_only:
    self.new_objects = []
    return self.save_existing_objects(commit)   # never dispatches to save_new_objects()
return self.save_existing_objects(commit) + self.save_new_objects(commit)
```

This is exactly where **gold** placed its only guard. The `V1 -> V2` transition was driven
by `F-2`/`PO-7`, **not** by a new failing test — the official tests use the stock factories
and never override `save_new_objects()` (see §5).

## 5. Verification

**Executed demonstration (not on the harness).** Three trees were built from the pristine
base commit (`baseline.patch` / `fvk.patch` / `gold.patch`), run against the local Django
(PYTHONPATH pinned to each tree — a venv's Django 4.2 initially shadowed the trees and gave
a false pass; corrected and re-verified):

```python
class _CustomFormSet(BaseModelFormSet):
    def save_new_objects(self, commit=True):      # realistic override, no super()
        self.new_objects = []
        for form in self.extra_forms:
            if form.has_changed() and not (self.can_delete and self._should_delete_form(form)):
                self.new_objects.append(self.save_new(form, commit=commit))
        return self.new_objects

AuthorFormSet = modelformset_factory(Author, formset=_CustomFormSet, fields='__all__', edit_only=True)
data = {'form-TOTAL_FORMS':'2','form-INITIAL_FORMS':'0','form-MAX_NUM_FORMS':'0',
        'form-0-name':'Arthur Rimbaud','form-1-name':'Walt Whitman'}
fs = AuthorFormSet(data); fs.is_valid(); fs.save()
Author.objects.count()   # contract says MUST stay 0
```

| Tree | override runs? | `Author.objects.count()` | Demo |
|------|----------------|--------------------------|------|
| **baseline** | yes (via `save()` virtual dispatch) | **2** — `['Arthur Rimbaud','Walt Whitman']` | **FAIL** (contract violated) |
| **fvk** | no (short-circuited in `save()`) | **0** | OK |
| **gold** | no (short-circuited in `save()`) | **0** | OK |

**Why the suite missed it.** The 3 official `FAIL_TO_PASS` tests (`test_edit_only`,
`test_edit_only_inlineformset_factory`, `test_edit_only_object_outside_of_queryset`) all use
the **stock** factories with no custom `save_new_objects()` override. On the stock class
baseline's helper guard *is* reached, so all three pass on baseline. The full 73-test
`model_formsets` suite also passes identically on baseline and fvk. The tests never subclass
and re-implement `save_new_objects()`, so they never exercise the virtual-dispatch path where
the guard's *location* matters.

**Gold comparison.** Gold puts the `edit_only` guard at `save()` only, leaving
`save_new_objects()` untouched. fvk matches gold at this exact site (and adds a redundant
helper guard). Baseline placed its guard at the *opposite* site from gold (helper, not
`save()`) and omitted it where gold actually put it; fvk is strictly closer to gold.

## 6. Boundaries & honesty

- **Severity: Low.** The divergence only manifests when application code subclasses the
  formset and overrides `save_new_objects()` without `super()`. `save_new_objects()` is *not*
  a documented public hook, so it is a semi-private extension point; the documented hooks
  `save_new()`/`save_existing()` do not distinguish baseline from fvk. The narrow trigger is
  what keeps this Low; it is still a genuine correctness improvement landing on the
  maintainers' fix location.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-model-formset.k`](../results/verified017-codex-XC-MINI-PRO-AHP-20260616T052940Z/django__django-14725/fvk/mini-model-formset.k),
  [`model-formset-spec.k`](../results/verified017-codex-XC-MINI-PRO-AHP-20260616T052940Z/django__django-14725/fvk/model-formset-spec.k))
  and the `kompile`/`kprove` commands were *written but never run* — the FVK artifacts say
  so explicitly
  ([`fvk/PROOF.md`](../results/verified017-codex-XC-MINI-PRO-AHP-20260616T052940Z/django__django-14725/fvk/PROOF.md#L3)).
  We claim **proof-structured reasoning**, not a machine-checked proof.
- **Attribution.** This instance has no harness `_proof`; verification is the executed
  demonstration above on three separately built trees (baseline creates 2, fvk/gold create
  0). FVK's own finding F-2 predicted exactly this mechanism, and it was empirically
  confirmed. A subclass that overrides `save()` *entirely* can still ignore `edit_only`
  (F-7) — a normal Python subclassing boundary, outside the base class's guarantee.

## Artifact map

| Claim | Source |
|---|---|
| Issue text | [`_materials/problem_statement.md`](../verified500_analysis/django__django-14725/_materials/problem_statement.md#L1) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified017-codex-XC-MINI-PRO-AHP-20260616T052940Z/django__django-14725/solutions/solution_baseline.patch) |
| Baseline reasoning | [`reports/baseline_notes.md`](../results/verified017-codex-XC-MINI-PRO-AHP-20260616T052940Z/django__django-14725/reports/baseline_notes.md#L38) |
| FVK patch | [`solutions/solution_fvk.patch`](../results/verified017-codex-XC-MINI-PRO-AHP-20260616T052940Z/django__django-14725/solutions/solution_fvk.patch) |
| Gold patch | [`_materials/gold.patch`](../verified500_analysis/django__django-14725/_materials/gold.patch) |
| Intent I-7 (no un-audited dispatch) | [`fvk/SPEC.md#L48`](../results/verified017-codex-XC-MINI-PRO-AHP-20260616T052940Z/django__django-14725/fvk/SPEC.md#L48) |
| Evidence E-7 (public dispatch point) | [`fvk/SPEC.md#L83`](../results/verified017-codex-XC-MINI-PRO-AHP-20260616T052940Z/django__django-14725/fvk/SPEC.md#L83) |
| Obligation PO-7 | [`fvk/PROOF_OBLIGATIONS.md#L69`](../results/verified017-codex-XC-MINI-PRO-AHP-20260616T052940Z/django__django-14725/fvk/PROOF_OBLIGATIONS.md#L69) |
| Finding F-2 | [`fvk/FINDINGS.md#L27`](../results/verified017-codex-XC-MINI-PRO-AHP-20260616T052940Z/django__django-14725/fvk/FINDINGS.md#L27) |
| Iteration decision (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L7`](../results/verified017-codex-XC-MINI-PRO-AHP-20260616T052940Z/django__django-14725/fvk/ITERATION_GUIDANCE.md#L7) |
| Decision trace | [`reports/fvk_notes.md#L3`](../results/verified017-codex-XC-MINI-PRO-AHP-20260616T052940Z/django__django-14725/reports/fvk_notes.md#L3) |
| Constructed K core | [`fvk/mini-model-formset.k`](../results/verified017-codex-XC-MINI-PRO-AHP-20260616T052940Z/django__django-14725/fvk/mini-model-formset.k), [`fvk/model-formset-spec.k`](../results/verified017-codex-XC-MINI-PRO-AHP-20260616T052940Z/django__django-14725/fvk/model-formset-spec.k) |
| Proof status (not machine-checked) | [`fvk/PROOF.md#L3`](../results/verified017-codex-XC-MINI-PRO-AHP-20260616T052940Z/django__django-14725/fvk/PROOF.md#L3) |
