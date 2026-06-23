# django__django-15916

## Summary

**Severity:** Medium — baseline keeps a separate base-form callback fallback in
`ModelFormMetaclass.__new__()`, so a valid subclass that supplies a *replacement*
`Meta` with no `formfield_callback` silently builds its fields with the base
form's callback instead of none, a realistic but scoped wrong-callback defect.

Baseline's core fix is correct: it makes `Meta.formfield_callback` a first-class
`ModelFormOptions` option and stops the `modelform_factory()` default `None` from
masking a base form's callback, and the baseline patch passed the official
SWE-bench evaluation. The residual is purely in the *fallback*: baseline retained
the legacy `base_formfield_callback` scan and applied it whenever a replacement
`Meta` lacked the option, which contradicts normal Python `Meta` resolution. FVK
located this by formalizing the issue's "consistency with other `Meta` options"
wording as an inheritance obligation (PO6) and removed the special fallback so the
callback comes only from the resolved `Meta` or an explicit top-level override.

| Arm | Reported masking/direct-`Meta` fixed; replacement-`Meta` subclass does **not** inherit a base callback | Resolved |
|---|---|---|
| baseline | reported cases fixed; but replacement-`Meta` subclass still inherits the base callback via the retained fallback | partial |
| gold (human oracle) | reported cases fixed; callback resolved through normal `Meta` resolution | yes |
| **fvk** | reported cases fixed; base fallback removed, so a replacement `Meta` resolves no callback | yes |

## 1. The issue and the real defect

The issue is that `modelform_factory(model, form=BaseForm)` with no callback
argument *"uses no callback instead of the `formfield_callback` of the base form
provided"*, and the expected behavior is that the generated form *"uses the
`formfield_callback` specified in the `Meta` attribute"*
([`fvk/SPEC.md` E1](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/SPEC.md#L26),
[E2](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/SPEC.md#L36)).
The evidence ledger records the two observables verbatim
([E1/E2](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/PUBLIC_EVIDENCE_LEDGER.md#L7))
together with the project hint that the option *"support it for consistency with
other `Meta` options"*
([E3](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/PUBLIC_EVIDENCE_LEDGER.md#L9)).

The original root cause was two-fold: `modelform_factory()` always installed a
top-level `formfield_callback = None` attribute that the metaclass then used,
masking any `Meta` callback; and `ModelFormMetaclass` never read the current
form's `Meta.formfield_callback` at all
([`reports/baseline_notes.md`](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/reports/baseline_notes.md#L4)).
The user-facing observable is that fields are generated with the wrong callback —
`None` where a `Meta` callback was intended.

## 2. Baseline's fix — and where it stopped

Baseline's diagnosis and the shape of its fix are correct. It adds
`formfield_callback` to `ModelFormOptions`
([baseline patch, `ModelFormOptions`](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/solutions/solution_baseline.patch#L9)),
distinguishes "provided" from "default `None`" in the metaclass, passes
`opts.formfield_callback` to `fields_for_model()`, and stops the factory from
installing a top-level `None` override
([baseline patch, factory hunk](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/solutions/solution_baseline.patch#L62)).
Those edits fix exactly the reported masking and direct-`Meta` cases.

The choice that stops one step short is the *fallback*. Baseline kept the legacy
`base_formfield_callback` scan over base classes and, when no top-level override
was provided, resolved the callback as

```python
if not formfield_callback_provided:
    formfield_callback = (
        opts.formfield_callback
        if hasattr(meta, "formfield_callback")
        else base_formfield_callback
    )
```

([baseline patch, fallback branch](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/solutions/solution_baseline.patch#L33)).
Baseline reasoned this through deliberately: it assumed the callback should be
*"inherited from the base form when a replacement `Meta` class omits the option"*
([`reports/baseline_notes.md`](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/reports/baseline_notes.md#L38)).
That assumption is the gap. When a subclass defines its *own* replacement `Meta`
without the option, `hasattr(meta, "formfield_callback")` is false, so baseline
falls through to `base_formfield_callback` — handing that subclass the base form's
callback, even though normal Python `Meta` resolution says a replacement `Meta`
should not inherit a single option from a parent `Meta`. The unmet obligation is
that callback inheritance must follow the same rules as every other `Meta`
option: a replacement `Meta` does not receive an isolated callback fallback from
the base `Meta`
([`fvk/INTENT_SPEC.md` item 6](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/INTENT_SPEC.md#L17)).

## 3. How FVK formally captured the gap

FVK started from the issue's "consistency with other `Meta` options" framing
rather than the single reported symptom, and wrote the inheritance rule into the
intent:

> *"`formfield_callback` should behave consistently with other `ModelForm` `Meta`
> options: normal Python inner-class resolution applies. A subclass with no
> `Meta` uses the first parent's `Meta`; a subclass with a replacement `Meta`
> uses that replacement and does not receive an isolated callback fallback from
> the base `Meta`."*
> — [`fvk/INTENT_SPEC.md` item 6](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/INTENT_SPEC.md#L17)

That intent is pinned to a concrete documentation fact found by source audit —
Django's own ModelForm inheritance rules — not to the reported test:

> **E4:** *`repo/docs/topics/forms/modelforms.txt` says normal Python name
> resolution applies: the child's `Meta`, if present, otherwise the first
> parent's `Meta`.* → *"A subclass that replaces `Meta` without inheriting or
> defining `formfield_callback` must not receive only that option from a base
> `Meta`."*
> — [`fvk/SPEC.md` E4](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/SPEC.md#L57)

The breadth question is then discharged into a dedicated obligation that the
reported tests cannot see:

> **PO6: Replacement Meta Does Not Leak Base Callback.** *Precondition: child form
> defines a replacement `Meta` without `formfield_callback`; base form `Meta` has
> a callback. Postcondition: child form resolves no callback.*
> — [`fvk/PROOF_OBLIGATIONS.md` PO6](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/PROOF_OBLIGATIONS.md#L57)

This is the gap located by reasoning: the issue and its tests only ask that the
factory-omitted and direct-`Meta` cases resolve the right callback (PO1
[here](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/PROOF_OBLIGATIONS.md#L5),
PO2
[here](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/PROOF_OBLIGATIONS.md#L17)),
but the formal contract additionally states that a replacement `Meta` must resolve
*no* callback — a property no test in the suite checks, and exactly the one
baseline's retained fallback violates. The companion PO7 confirms the legitimate
inheritance case (a subclass with *no* `Meta` still gets the parent `Meta`
callback) so the fix does not over-correct
([PO7](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/PROOF_OBLIGATIONS.md#L68)).

## 4. From formal output to the fix

The audit raised one code-bug finding against V1 (baseline), tied to its
obligation and then to a concrete V2 edit.

- Finding — V1 leaked the base callback through a replacement `Meta`:

  > **F1: V1 Inherited Base Callback Through Replacement Meta.** *V1 observed by
  > code inspection: `ChildForm` used `base_callback` because V1 fell back to
  > `base_formfield_callback` when the replacement `Meta` lacked the option …
  > Change made: removed the special base-form fallback from
  > `ModelFormMetaclass.__new__()`.*
  > — [`fvk/FINDINGS.md` F1](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/FINDINGS.md#L5)

  The findings explicitly mark the reported fixes (F2 factory masking, F3 direct
  `Meta`) as *resolved by V1 and preserved in V2*, so the V2 work is narrow
  ([F2](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/FINDINGS.md#L34),
  [F3](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/FINDINGS.md#L53)).

- Iteration guidance turned F1 into the single V2 refinement:

  > *"V1 used a separate base-form fallback for `formfield_callback`, which could
  > make a child form with a replacement `Meta` inherit only that option from the
  > base `Meta`. This conflicted with the documented normal Python `Meta`
  > resolution rules. V2 removes that fallback."*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/ITERATION_GUIDANCE.md#L9)

- The decision trace records the edit and its provenance:

  > *"That behavior violated `fvk/PROOF_OBLIGATIONS.md` PO6:
  > `REPLACED-META-DOES-NOT-LEAK-BASE` … The V2 edit removes the special base
  > fallback. The metaclass now resolves the callback from an explicit top-level
  > class attribute if present; otherwise it uses `opts.formfield_callback` from
  > the already resolved `Meta` object."*
  > — [`reports/fvk_notes.md`](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/reports/fvk_notes.md#L13)

The causal chain:

```
INTENT_SPEC item 6 / EVIDENCE E4  ->  PO6 (replacement Meta leaks no base callback)
                                  ->  F1 (V1 fallback leaks base_callback)
                                  ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 patch
```

The V2 patch
([`solutions/solution_fvk.patch`](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/solutions/solution_fvk.patch))
deletes the entire `base_formfield_callback` scan loop
([fvk patch, removed loop](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/solutions/solution_fvk.patch#L14))
and collapses the resolution to the resolved `Meta` only:

```python
if not formfield_callback_provided:
    formfield_callback = opts.formfield_callback
opts.formfield_callback = formfield_callback
```

([fvk patch, resolved-only branch](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/solutions/solution_fvk.patch#L34)).
Everything else (the `ModelFormOptions` option, the `is not None` factory checks,
the top-level override path) is identical to baseline. The `V1 -> V2` transition
was driven entirely by the formal finding F1 and obligation PO6 — **not** by any
new test; the run had no execution environment and added no tests
([`fvk/FINDINGS.md` F5](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/FINDINGS.md#L89)).

## 5. Verification

**Tier 3 — source-and-artifact reviewed; not executed.** The run forbade running
tests, Python, or K tooling
([`prompts/fvk.md`](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/prompts/fvk.md#L27)),
so there is no harness RED/GREEN and no executed behavioral demonstration. What
was inspected, and supports the conclusions above:

- The two patches were diffed against each other and against the issue. Both add
  the `ModelFormOptions.formfield_callback` option, both pass
  `opts.formfield_callback` to `fields_for_model()`, and both use `is not None`
  in `modelform_factory()`; they differ *only* in the metaclass fallback —
  baseline retains the conditional `base_formfield_callback` branch
  ([baseline](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/solutions/solution_baseline.patch#L33)),
  FVK removes the scan loop and resolves from `opts.formfield_callback` alone
  ([fvk](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/solutions/solution_fvk.patch#L34)).
  Both therefore fix the reported masking and direct-`Meta` cases; FVK
  additionally makes a replacement-`Meta` subclass resolve no callback.

- The compatibility audit confirms by source inspection that V2 keeps the
  `modelform_factory` / `modelformset_factory` / `inlineformset_factory` public
  signatures unchanged, keeps the `fields_for_model()` callability validation
  untouched, and changes class construction only on the callback-selection path
  ([`fvk/PUBLIC_COMPATIBILITY_AUDIT.md`](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/PUBLIC_COMPATIBILITY_AUDIT.md#L16)).

**Comparison to the human oracle.** The official gold fix resolves the callback
through normal `Meta` resolution rather than a special base-form fallback,
matching FVK's V2 behavior; baseline's retained fallback is the wider variant that
leaks a base callback into a replacement-`Meta` subclass. FVK re-derived that
boundary from the PO6 inheritance obligation rather than from the reference
solution. (No gold artifact is attached to this non-curated run, so this is a
prose comparison only.)

## 6. Boundaries & honesty

- **Severity: Medium.** The trigger breadth is wider than a Low compatibility
  edge but narrower than silent corruption. Baseline's residual produces a
  *wrong callback object* for a perfectly valid form class: a subclass that
  declares its own replacement `Meta` (a common pattern) without
  `formfield_callback` builds its fields with the base form's callback instead of
  none. That can change field requiredness, widgets, or validation — realistic
  and user-reachable — but it is scoped to the replacement-`Meta`-with-base-callback
  case rather than affecting every form, and it is a wrong-behavior bug, not
  generally silent data loss. That places it at Medium per the rubric
  ([`fvk/FINDINGS.md` F1](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/FINDINGS.md#L5),
  [`fvk/PROOF_OBLIGATIONS.md` PO6](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/PROOF_OBLIGATIONS.md#L57)).

- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-python-form-callback.k`](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/mini-python-form-callback.k),
  [`modelform-callback-spec.k`](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/modelform-callback-spec.k))
  and the `kompile`/`kast`/`kprove` commands were written but never run; the run
  artifacts state this explicitly
  ([`fvk/PROOF.md`](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/PROOF.md#L3),
  [`fvk/FINDINGS.md` F5](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/FINDINGS.md#L89)).
  The claim is proof-*structured* reasoning — a contract whose obligations (PO1,
  PO2, PO6, PO7) are discharged by construction over a reduced callback-selection
  semantics — not a machine-checked proof.

- **Attribution.** The existing doc's framing ("baseline retained a separate
  base-form fallback that can inherit a base callback even when a subclass
  supplies a replacement `Meta`; FVK removes it and resolves only from a top-level
  attribute or the resolved `Meta`") is **confirmed by the actual patches**: the
  sole delta between the two arms is the deleted `base_formfield_callback` scan
  and fallback branch. The doc's references to F1/PO6 (`REPLACED-META-DOES-NOT-LEAK-BASE`)
  and to F2/F3 preserving the reported fixes map correctly onto the artifacts and
  are linked precisely above. No machine-checked verdict and no executed
  demonstration exist for this instance; the conclusions rest on patch and source
  review.

## Artifact map

| Claim | Source |
|---|---|
| Issue text (masking, expected `Meta` callback) | [`fvk/SPEC.md` E1/E2](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/SPEC.md#L26), [`fvk/PUBLIC_EVIDENCE_LEDGER.md` E1/E2](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/PUBLIC_EVIDENCE_LEDGER.md#L7) |
| Original root cause (factory `None`, unread `Meta`) | [`reports/baseline_notes.md`](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/reports/baseline_notes.md#L4) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/solutions/solution_baseline.patch#L33) |
| Baseline reasoning (base-form fallback assumption) | [`reports/baseline_notes.md`](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/reports/baseline_notes.md#L38) |
| FVK patch (fallback removed) | [`solutions/solution_fvk.patch`](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/solutions/solution_fvk.patch#L34) |
| Intent item 6 (consistent `Meta` resolution) | [`fvk/INTENT_SPEC.md` item 6](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/INTENT_SPEC.md#L17) |
| Evidence E4 (Django inheritance docs) | [`fvk/SPEC.md` E4](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/SPEC.md#L57), [`fvk/PUBLIC_EVIDENCE_LEDGER.md` E4](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/PUBLIC_EVIDENCE_LEDGER.md#L10) |
| Obligation PO6 (replacement `Meta` no leak) | [`fvk/PROOF_OBLIGATIONS.md` PO6](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/PROOF_OBLIGATIONS.md#L57) |
| Obligation PO7 (inherited `Meta` preserved) | [`fvk/PROOF_OBLIGATIONS.md` PO7](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/PROOF_OBLIGATIONS.md#L68) |
| Finding F1 (V1 leaked base callback) | [`fvk/FINDINGS.md` F1](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/FINDINGS.md#L5) |
| Findings F2/F3 (reported fixes preserved) | [`fvk/FINDINGS.md` F2](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/FINDINGS.md#L34), [F3](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/FINDINGS.md#L53) |
| Iteration guidance (V1→V2 refinement) | [`fvk/ITERATION_GUIDANCE.md`](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/ITERATION_GUIDANCE.md#L9) |
| Decision trace (provenance of edit) | [`reports/fvk_notes.md`](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/reports/fvk_notes.md#L13) |
| Compatibility audit | [`fvk/PUBLIC_COMPATIBILITY_AUDIT.md`](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/PUBLIC_COMPATIBILITY_AUDIT.md#L16) |
| Honesty boundary (no execution) | [`fvk/FINDINGS.md` F5](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/FINDINGS.md#L89) |
| Proof status / kprove not run | [`fvk/PROOF.md`](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/PROOF.md#L3) |
| No-execution constraint | [`prompts/fvk.md`](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/prompts/fvk.md#L27) |
| Constructed K core | [`fvk/mini-python-form-callback.k`](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/mini-python-form-callback.k), [`fvk/modelform-callback-spec.k`](../results/verified021-codex-archlinux-20260616T035839Z/django__django-15916/fvk/modelform-callback-spec.k) |
