# Intent Specification

Status: constructed from public evidence only.

## Required behavior

I-001. For `JSONField` `has_key`, `has_keys`, and `has_any_keys`, each lookup
argument names a JSON object key. A key whose text is numeric, such as `"1111"`,
must be treated as an object member name, not as a JSON array index.

I-002. The behavior applies to SQLite, MySQL, and Oracle path-based
implementations. PostgreSQL already uses key operators and must not be
regressed.

I-003. Existing nested JSON transform behavior must be preserved: numeric
transform path components before the key-existence test may represent array
indexes. Public examples include `value__d__1__has_key="f"` and
`value__1__has_key="b"`.

I-004. Internal uses of `HasKey` to implement `KeyTransform` existence checks,
such as `key__isnull=False` and Oracle JSON-null exact matching, must preserve
normal `KeyTransform` path semantics. In those contexts a numeric final
transform segment remains an array index.

I-005. The patch should be minimal: SQL templates, logical operators, lookup
names, public method call compatibility, and unsupported-backend behavior are
outside the reported defect and should remain unchanged.

## Domain assumptions

D-001. The formalized helper path is called with a non-empty right-hand
transform list when it is asked to compile a final key. This is a local helper
precondition: each `has_key` item and each `KeyTransform` has at least one final
segment.

D-002. The model abstracts `json.dumps(str(key))` as `member(keyText(key))`. It
tracks the observable distinction relevant to this issue: `member("1111")` vs
`index(1111)`.
