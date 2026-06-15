# Formal Specification in English

Status: paraphrase of `fvk/admin-display-spec.k`.

## C-JSON-EXAMPLE

For the concrete issue example `jsonObject("foo", "bar")` and a built-in JSONField, `displayForField` returns `preparedJson(jsonObject("foo", "bar"), "default")`.

## C-JSON-NONINVALID

For any value `V` that is neither `none` nor `invalidJson(_)`, and for any built-in JSONField carrying encoder `ENC`, `displayForField(V, jsonField(ENC), EMPTY)` returns `preparedJson(V, ENC)`.

## C-JSON-INVALID

For any invalid JSON input string `S`, `displayForField(invalidJson(S), jsonField(ENC), EMPTY)` returns `rawJson(S)`.

## C-POSTGRES-SUBCLASS

For the deprecated postgres JSONField subclass and any non-null, non-invalid value, `displayForField` returns the same prepared JSON result as the built-in JSONField.

## C-POSTGRES-INVALID

For the deprecated postgres JSONField subclass and any invalid JSON input string `S`, `displayForField` returns `rawJson(S)`.

## C-JSON-NONE

For `none` with a built-in JSONField, `displayForField(none, jsonField(ENC), EMPTY)` returns `EMPTY`.

## C-NONJSON-FALLBACK

For a JSON-shaped object value paired with a non-JSON field, `displayForField` returns `pyRepr(V)`, showing the generic fallback remains distinct from the JSONField path.
