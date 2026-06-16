# FVK Findings

Status: constructed, not machine-checked. No tests, Python code, or K tooling were executed.

## F-001 - Pre-V1 Inline Serialization Defect Is Resolved

Classification: resolved code bug.

Evidence:

- Public intent: `benchmark/PROBLEM.md` says extra autocomplete result fields previously required fully overriding `AutocompleteJsonView.get()`.
- Current source: `AutocompleteJsonView.get()` now calls `self.serialize_result(obj, to_field_name)` for each object in `context['object_list']`.

Input scenario:

- A subclass wants to add `notes` to each autocomplete result.

Observed before V1:

- The subclass had to override the whole `get()` method to alter one dictionary expression.

Expected:

- The subclass overrides only `serialize_result(self, obj, to_field_name)`.

Current audit result:

- V1 satisfies the expectation through dynamic dispatch. See PO-1 and PO-3.

## F-002 - Default Response Shape Is Preserved

Classification: confirmed frame condition.

Evidence:

- Public intent: the proposed default `serialize_result()` returns `{'id': str(getattr(obj, to_field_name)), 'text': str(obj)}`.
- Current source: `serialize_result()` returns that exact dictionary.

Input scenario:

- Default `AutocompleteJsonView` handles a successful autocomplete request with objects in `context['object_list']`.

Observed in V1:

- Each default item is serialized with the same `id` and `text` expressions used before extraction.

Expected:

- Existing consumers still receive `results` entries with `id` and `text`.

Current audit result:

- V1 satisfies the expectation. See PO-2.

## F-003 - Pagination and Surrounding Response Are Preserved

Classification: confirmed frame condition.

Evidence:

- Public intent: the before/after snippets keep `pagination: {'more': context['page_obj'].has_next()}` unchanged.
- Current source: V1 leaves the `pagination` expression untouched.

Input scenario:

- Any successful autocomplete response, with or without another result page.

Observed in V1:

- `pagination.more` is still taken from `context['page_obj'].has_next()`.

Expected:

- Refactoring result serialization must not alter pagination.

Current audit result:

- V1 satisfies the expectation. See PO-4.

## F-004 - Public Override Compatibility Is Clean

Classification: compatibility confirmed.

Evidence:

- Current source search under non-test `repo/django` found no pre-existing `serialize_result` override.
- `get()` calls `self.serialize_result(obj, to_field_name)` positionally.
- Admin URL wiring and widget URL generation remain unchanged.

Input scenario:

- Existing Django code uses the default admin autocomplete view.
- New subclass code defines `serialize_result(self, obj, to_field_name)`.

Observed in V1:

- Existing default view construction is unchanged.
- New subclass overrides receive the two expected positional arguments.

Expected:

- No existing public callsite breaks, and the new extension point is usable as shown in the issue.

Current audit result:

- V1 satisfies the compatibility obligation. See PO-5.

## F-005 - No V2 Source Edit Is Justified

Classification: no blocking code finding.

Evidence:

- F-001 through F-004 discharge the issue's extension-point, default-preservation, pagination-preservation, and compatibility obligations.
- No proof obligation requires a different method signature, response shape, or call placement.

Decision:

- Keep V1 source unchanged.

Trace:

- Supported by PO-1 through PO-5.

## F-006 - Proof Is Constructed but Not Machine-Checked

Classification: verification environment limitation.

Evidence:

- Task instructions forbid running tests, Python, `kompile`, or `kprove`.

Impact:

- The FVK artifacts can justify the code decision by intent and constructed proof, but test deletion is not recommended.

Decision:

- Record the commands in `PROOF_OBLIGATIONS.md` and `PROOF.md`; do not execute them.
