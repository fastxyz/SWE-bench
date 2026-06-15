# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: JSONField example object does not use Python repr

Claim: `displayForField(jsonObject("foo", "bar"), jsonField("default"), emptyDisplay("-"))` reaches `preparedJson(jsonObject("foo", "bar"), "default")`, not `pyRepr(...)`.

Evidence: E1, E2.

K claim: C-JSON-EXAMPLE.

Status: discharged by V1.

## PO-2: All non-null, non-invalid JSONField values use JSON prepare_value

Claim: for any value `V` where `V` is not `none` and not `invalidJson(_)`, `displayForField(V, jsonField(ENC), EMPTY)` reaches `preparedJson(V, ENC)`.

Evidence: E1, E3, E5.

K claim: C-JSON-NONINVALID.

Status: discharged by V1.

## PO-3: InvalidJSONInput is preserved

Claim: `displayForField(invalidJson(S), jsonField(ENC), EMPTY)` reaches `rawJson(S)`.

Evidence: E3, E6.

K claim: C-JSON-INVALID.

Status: discharged by V1.

## PO-4: JSONField subclasses use the same branch

Claim: `displayForField(V, postgresJsonField(ENC), EMPTY)` reaches the same result as `displayForField(V, jsonField(ENC), EMPTY)` for non-null JSON values, including invalid JSON input.

Evidence: E4 and source inheritance of `contrib.postgres.fields.JSONField` from built-in `JSONField`.

K claims: C-POSTGRES-SUBCLASS and C-POSTGRES-INVALID.

Status: discharged by V1.

## PO-5: `None` remains empty display

Claim: `displayForField(none, jsonField(ENC), EMPTY)` reaches `EMPTY`.

Evidence: E7.

K claim: C-JSON-NONE.

Status: discharged by V1.

## PO-6: Non-JSON fallback is unchanged

Claim: a JSON-shaped value paired with `normalField` still reaches `pyRepr(V)` in the formal model.

Evidence: compatibility/frame condition from the existing helper.

K claim: C-NONJSON-FALLBACK.

Status: discharged by V1.

## PO-7: Public API compatibility

Claim: the fix must not change the signature or required caller protocol of `display_for_field()`.

Evidence: public callers in `django.contrib.admin.helpers` and `django.contrib.admin.templatetags.admin_list` still call the same three-argument function.

Audit: `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

Status: discharged by V1.
