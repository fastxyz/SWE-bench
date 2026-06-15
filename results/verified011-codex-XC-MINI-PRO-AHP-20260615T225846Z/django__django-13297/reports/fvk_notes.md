# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not surface a source-code defect that
requires another edit.

## Source decision trace

The original regression is captured in `fvk/FINDINGS.md` as F1 and formalized
as PO1 in `fvk/PROOF_OBLIGATIONS.md`: URL kwargs must reach
`get_context_data()` as raw values. V1 satisfies this because
`TemplateView.get()` calls `self.get_context_data(**kwargs)` before invoking the
deprecation wrapper helper.

The compatibility requirement for deprecated direct context access is captured
as F2 and PO2/PO4: unchanged URL kwargs that remain in the final context should
still be lazily wrapped so the existing `RemovedInDjango40Warning` is emitted
when the value is forced. V1 satisfies this by applying
`_wrap_url_kwargs_with_deprecation_warning(context, kwargs)` after context
construction and before `render_to_response(context)`.

The override-safety requirement is captured as F3 and PO3: keys removed from
the returned context must stay removed, and keys replaced by overrides or
`extra_context` must not be overwritten. V1 satisfies this with the helper guard
`if key not in context or context[key] is not value: continue`. This also covers
the boundary case where a URL kwarg value is `None`, because missing keys are
checked before lookup.

The public compatibility requirement is captured as F4 and PO5. No public
method signature changed, and the private helper has no allowed-source callsites
outside `repo/django/views/generic/base.py`. This supports keeping V1's source
shape.

The rejected alternative is captured as F5 and PO6. The public hint says ORM
filtering with `SimpleLazyObject` was already unsupported, so changing ORM
adaptation would address a broader non-regression behavior rather than the
`TemplateView` regression.

## FVK artifacts

The required artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

To satisfy the FVK methodology's adequacy and formal-core requirements, I also
added compact supporting artifacts:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-templateview.k`
- `fvk/templateview-spec.k`

The constructed K artifacts model only the behavior relevant to the issue:
raw-kwargs forwarding, post-context wrapping, and frame preservation for
removed or replaced context entries. They are labeled constructed, not
machine-checked.

## Execution constraints

No tests, Python, `kompile`, `kast`, or `kprove` were run, per the task
constraints. The commands are recorded in the FVK artifacts for a later
environment that supports machine checking.
