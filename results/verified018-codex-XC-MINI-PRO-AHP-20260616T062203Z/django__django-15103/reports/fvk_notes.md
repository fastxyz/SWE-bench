# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found that the current source changes satisfy the intent-derived runtime obligations for making `element_id` optional.

## Trace to Findings and Proof Obligations

`F-01` identified the original bug: the Python helper and template filter had no no-ID path. V1 addresses this through:

- `PO-1`: `django.utils.html.json_script()` now has `element_id=None`.
- `PO-2`: the utility emits the no-ID script wrapper when `element_id is None`.
- `PO-5`: the template filter now has a defaulted `element_id`, so `FilterExpression.args_check()` accepts `{{ value|json_script }}`.
- `PO-6`: the template filter delegates to the utility without a separate rendering path.

`F-02` required existing ID-present behavior to remain compatible. V1 addresses this through:

- `PO-3`: the non-`None` branch keeps the existing `format_html('<script id="{}" ...')` output shape.
- `PO-4`: both branches continue using the same escaped `json_str`.
- `PO-7`: adding a default does not change existing two-argument utility calls or one-argument template-filter calls.

`F-03` recorded that an explicitly empty string ID is under-specified by public intent. I kept V1's `element_id is None` check unchanged because `PO-8` says not to use that ambiguous case to prove or disprove the required omitted-argument behavior. Preserving existing provided-argument behavior is the narrower runtime change.

`F-04` recorded a documentation/test coverage gap. I did not edit tests because the task forbids modifying test files. I also did not edit documentation in this FVK pass because the runtime source obligations are already discharged; `fvk/ITERATION_GUIDANCE.md` records the documentation follow-up.

`F-05` recorded that the proof is constructed but not machine-checked. I emitted `fvk/mini-python-json-script.k`, `fvk/json-script-spec.k`, and the exact commands in `fvk/PROOF.md`, but did not run them because the task forbids Python, test, `kompile`, and `kprove` execution.

## FVK Artifacts Produced

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- `fvk/mini-python-json-script.k`
- `fvk/json-script-spec.k`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

## Source Changes in This FVK Pass

No additional source files were changed after V1.
