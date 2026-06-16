# FINDINGS

Status: constructed, not machine-checked.

## F1 - V1 fixes the reported alias recording bug

Classification: fixed code bug.

Evidence: ledger E1-E8; proof obligations PO1 and PO2.

Input: callable annotations `data: JSONObject -> JSONObject`, config
`autodoc_typehints = 'description'`, and
`autodoc_type_aliases = {'JSONObject': 'types.JSONObject'}`.

Observed before V1: `record_typehints()` called `inspect.signature(obj)` without
aliases, so the recorded strings could become expanded values such as
`Dict[str, Any]`.

Expected: recorded strings are `types.JSONObject` for both `data` and `return`.

V1 status: fixed by passing `type_aliases=app.config.autodoc_type_aliases` into
`inspect.signature()` before `typing.stringify()`.

## F2 - Merge path preserves the corrected string

Classification: confirmed behavior.

Evidence: ledger E9; proof obligation PO3.

Input: recorded annotations `data -> types.JSONObject`,
`return -> types.JSONObject`, description-mode object node without existing type
fields.

Observed by source inspection: `modify_field_list()` inserts `nodes.paragraph('', annotation)`
for `type data` and `rtype`; it does not re-resolve or expand the string.

Expected: generated field strings remain `types.JSONObject`.

V1 status: confirmed. No merge-path source edit is needed.

## F3 - Public compatibility is preserved

Classification: compatibility confirmation.

Evidence: `PUBLIC_COMPATIBILITY_AUDIT.md`; proof obligation PO5.

Input: autodoc event dispatch to `record_typehints()` and later consumption of
`app.env.temp_data['annotations']`.

Observed by source inspection: V1 changes only an internal argument to an existing
helper and keeps callback signature plus stored data shape unchanged.

Expected: extensions and later autodoc stages see the same callback API and
annotation map shape.

V1 status: confirmed. No compatibility edit is needed.

## F4 - Residual proof/tooling risk

Classification: proof capability gap.

Evidence: FVK method honesty gate; proof obligation PO6.

Input: the constructed K artifacts in this directory.

Observed: no `kompile`, `kast`, `kprove`, Python, or tests were run because this task
forbids execution.

Expected: machine-checking would be required to upgrade the proof from constructed
to machine-checked.

V1 status: not a code bug. Keep tests; do not remove or rewrite tests based on this
constructed proof.
