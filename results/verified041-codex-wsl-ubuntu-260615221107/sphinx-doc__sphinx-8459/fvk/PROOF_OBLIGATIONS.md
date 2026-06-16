# PROOF OBLIGATIONS

Status: constructed, not machine-checked.

## PO1 - Alias-aware recording

Statement: `record_typehints()` must obtain the signature with the configured
`autodoc_type_aliases` map.

Evidence: ledger E1-E8.

Discharge: V1 source line calls
`inspect.signature(obj, type_aliases=app.config.autodoc_type_aliases)`.

Result: discharged by source inspection and encoded by
`CLAIM-RECORD-ALIASED-ANNOTATIONS`.

## PO2 - Parameter and return coverage

Statement: both parameter annotations and return annotations must be recorded after
alias-aware resolution.

Evidence: issue expected output names both parameter type and return type; ledger E3.

Discharge: after the V1 signature call, the existing loops over
`sig.parameters.values()` and `sig.return_annotation` stringify the alias-aware
annotations.

Result: discharged by source inspection and encoded by
`CLAIM-RECORD-ALIASED-ANNOTATIONS`.

## PO3 - Merge preservation

Statement: description-mode field insertion must preserve recorded annotation
strings.

Evidence: ledger E4 and E9.

Discharge: `modify_field_list()` uses `annotation` directly as paragraph text for
generated `type NAME` and `rtype` fields.

Result: discharged by source inspection and encoded by
`CLAIM-MERGE-PRESERVES-RECORDED-ALIASES`.

## PO4 - Reject pre-fix output

Statement: `Dict[str, Any]` for the issue alias is the rejected legacy behavior, not
the intended postcondition.

Evidence: issue "Expected behavior" and ledger E3.

Discharge: `CLAIM-PREFIX-FAILS-ALIASED-ANNOTATIONS` models the old path and records
it only as a negative finding.

Result: discharged as a finding, not as accepted behavior.

## PO5 - Compatibility frame

Statement: the fix must not change public callback signatures or the annotation map
shape consumed by later autodoc code.

Evidence: compatibility audit.

Discharge: V1 changes only the argument passed into an existing helper and leaves
`annotation[param.name] = string` plus `annotation['return'] = string` unchanged.

Result: discharged by source inspection.

## PO6 - Honesty gate

Statement: proof status must remain "constructed, not machine-checked"; no test
removal is justified.

Evidence: task forbids execution and FVK docs require honesty labeling.

Discharge: all artifacts are labeled constructed; commands are written in `PROOF.md`
but not run.

Result: discharged.
