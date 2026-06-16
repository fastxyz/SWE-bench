# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public intent, source inspection, and proof-obligation construction only.

## F-01 - Original no-ID path was missing

Classification: code bug, resolved by V1.

Evidence: `benchmark/PROBLEM.md` requires `element_id` to be optional and says an ID is not needed for the reported use case.

Observed before V1: `django.utils.html.json_script(value)` had no default for `element_id`, and the template filter wrapper also required `element_id`. The template parser's `args_check()` would reject `{{ value|json_script }}` because the filter had two required positional parameters including the implicit input value.

Expected: The utility and filter no-argument paths are accepted and render a script tag without an `id` attribute.

V1 status: Satisfied by `PO-1`, `PO-2`, `PO-4`, and `PO-5`.

## F-02 - Existing ID-present behavior must remain compatible

Classification: compatibility obligation, satisfied by V1.

Evidence: public docs and tests show output with `id="hello-data"` or `id="test_id"` when an ID is supplied.

Observed in V1: The non-`None` branch still calls `format_html('<script id="{}" type="application/json">{}</script>', element_id, mark_safe(json_str))`.

Expected: Existing ID-present calls keep the same output shape and continue escaping the ID.

V1 status: Satisfied by `PO-3`, `PO-6`, and `PO-7`.

## F-03 - Explicit empty-string ID is under-specified

Classification: underspecified intent, no code change justified.

Evidence: The issue asks to make the argument optional and describes a use case where no ID is needed. It does not state whether an explicitly supplied empty string should omit the attribute or preserve the previous `id=""` output.

Observed in V1: `element_id == ""` follows the provided-ID branch because only `None` means absent.

Expected: No public-intent expectation can be derived for this exact case.

V1 status: Keep V1 unchanged. This behavior is not used to justify correctness for the required omitted-argument path; it is a compatibility-preserving choice outside the positive issue obligation.

## F-04 - Public docs and public tests cover only the ID-present example

Classification: documentation/test coverage gap, not a runtime code defect.

Evidence: `repo/docs/ref/templates/builtins.txt` documents the ID-present example, and public tests under `repo/tests` assert only ID-present output.

Observed in V1: Runtime code supports the no-ID path, but public docs and public tests do not demonstrate it.

Expected: A normal project follow-up should document the optional argument and add tests for `json_script(value)` and `{{ value|json_script }}`.

V1 status: No test files were modified because the task forbids it. No documentation file was changed because the benchmark repair target is non-test source code; this finding is recorded for iteration guidance.

## F-05 - Formal proof is constructed but not machine-checked

Classification: proof process limitation.

Evidence: The task forbids running tests, Python, `kompile`, or `kprove`.

Observed: The K files and proof commands are emitted, but no tool output exists.

Expected: Treat the proof as constructed-only. Do not remove tests based on it until `kprove` can be run and returns `#Top`.

V1 status: No source change required.
