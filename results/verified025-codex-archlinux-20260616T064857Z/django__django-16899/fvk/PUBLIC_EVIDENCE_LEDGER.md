# Public Evidence Ledger

Status: constructed, not machine-checked.

## E-01

Source: prompt.

Quoted evidence: "current error message for the readonly_fields would indicate
the index of the value at fault but it will not include the field's name".

Semantic obligation: invalid `readonly_fields` errors must retain the indexed
path and add the missing configured field value.

Status: encoded in PO-01 and PO-02.

## E-02

Source: prompt.

Quoted evidence: "The value of 'readonly_fields[0]' is not a callable, an
attribute of 'CityInline', or an attribute of 'admin_checks.City'."

Semantic obligation: this is the legacy symptom. It is evidence that the old
message had the index but omitted the field value.

Status: SUSPECT legacy output; not accepted as the desired postcondition.

## E-03

Source: prompt.

Quoted evidence: "The value of 'list_editable[0]' refers to
'original_release', which is not contained in 'list_display'."

Semantic obligation: `readonly_fields` should follow the neighboring admin check
style by including "refers to '<field name>'" after the indexed option path.

Status: encoded in PO-01.

## E-04

Source: prompt.

Quoted evidence: "It would be good if we can unify this and include the field
name in the readonly_fields checks, it also eases the understanding of the error
when using the framework."

Semantic obligation: the user-visible check message must include the invalid
configured field name.

Status: encoded in PO-01.

## E-05

Source: implementation.

Quoted evidence: `_check_readonly_fields_item()` returns no error when the item
is callable, an attribute of the admin object, an attribute of the model class,
or a model field.

Semantic obligation: those valid cases are frame conditions and must remain
unchanged.

Status: encoded in PO-03.

## E-06

Source: implementation.

Quoted evidence: the invalid branch constructs `checks.Error(...,
obj=obj.__class__, id="admin.E035")`.

Semantic obligation: the fix changes only the message text, not the error id or
object metadata.

Status: encoded in PO-04.

## E-07

Source: docs.

Quoted evidence: `docs/ref/checks.txt` documents the admin system check
messages.

Semantic obligation: the `admin.E035` documentation should include the field
name once the runtime message does.

Status: surfaced as F-02 and addressed by the V2 docs update.

## E-08

Source: public-test.

Quoted evidence: existing public tests under `repo/tests/admin_checks/tests.py`
assert the old `admin.E035` message without the field value.

Semantic obligation: because this conflicts with E-01 through E-04, it is a
SUSPECT legacy-test obligation and must not veto the public issue intent.

Status: recorded as F-03; tests were not edited.
