# FVK Findings

Status: constructed, not machine-checked.

## F-01: V1 fixed the runtime message omission

Classification: code bug, fixed by V1.

Evidence: E-01 through E-04 and PO-01.

Input: a `readonly_fields` item such as `i_dont_exist` that is not callable, not
an attribute on the admin object, not an attribute on the model class, and not a
model field.

Observed before V1: `The value of 'readonly_fields[0]' is not a callable, an
attribute of 'CityInline', or an attribute of 'admin_checks.City'.`

Expected: the same error identifies the indexed setting and the invalid value,
for example `The value of 'readonly_fields[0]' refers to 'i_dont_exist', which
is not a callable, an attribute of 'CityInline', or an attribute of
'admin_checks.City'.`

Resolution: V1 changed the `admin.E035` message format in
`repo/django/contrib/admin/checks.py` to interpolate `field_name`.

## F-02: V1 left public check documentation stale

Classification: documentation compatibility gap, fixed by V2.

Evidence: E-07 and PO-05.

Input: a developer reading the `admin.E035` entry in `docs/ref/checks.txt`.

Observed in V1: the docs still described the old message shape without the
invalid field value.

Expected: the docs describe that `readonly_fields[n]` refers to `<field name>`,
matching the new runtime message.

Resolution: V2 updated `repo/docs/ref/checks.txt` for `admin.E035`.

## F-03: Public tests encode the legacy symptom

Classification: SUSPECT legacy-test evidence, not edited.

Evidence: E-08 and PO-06.

Input: existing public tests in `repo/tests/admin_checks/tests.py` that assert
the old `admin.E035` message.

Observed: the expected strings omit the invalid field value.

Expected: those tests would need to assert the new message if test edits were in
scope.

Resolution: no test files were modified because the benchmark forbids test
edits. The tests are not used as authority against the issue intent.

## Proof-derived findings from `/verify`

No code bug was found in V1's source change. The proof obligations cover the
invalid branch, caller label propagation, valid no-error branches, and error id
preservation. The only improvement obligation surfaced by the adequacy and
compatibility audit was F-02, the stale public documentation.
