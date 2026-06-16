# Formal Spec English

Status: constructed, not machine-checked.

This file paraphrases the K claims in `autodoc-typehints-spec.k`.

## CLAIM-RECORD-ALIASED-ANNOTATIONS

For a callable whose raw postponed annotations are `data -> JSONObject` and
`return -> JSONObject`, and whose configured alias map contains
`JSONObject -> types.JSONObject`, running the abstract `recordTypehints` transition
stores `data -> types.JSONObject` and `return -> types.JSONObject` for the object
name. This is the V1 behavior.

## CLAIM-MERGE-PRESERVES-RECORDED-ALIASES

If description-mode merging receives recorded annotations whose strings are
`types.JSONObject`, then generated fields contain `type data = types.JSONObject`
and `rtype = types.JSONObject`. The merge step does not re-expand or rewrite the
recorded alias string.

## CLAIM-PREFIX-FAILS-ALIASED-ANNOTATIONS

The pre-fix abstract transition, which records type hints without the configured
alias map, stores the expanded annotation string `Dict[str, Any]` for the same raw
annotation and alias configuration. This is the reported bug path and is not an
allowed postcondition for the fixed code.

## CLAIM-NO-DUPLICATE-USER-FIELDS

If a field list already contains a type field for a parameter or an `rtype` field,
the merge operation must not add another generated field for that same key. This is
a frame condition preserving existing `modify_field_list()` behavior.
