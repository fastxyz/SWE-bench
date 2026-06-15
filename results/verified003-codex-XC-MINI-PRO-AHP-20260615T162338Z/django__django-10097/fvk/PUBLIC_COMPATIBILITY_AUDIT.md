# Public Compatibility Audit

Status: pass with framed behavior changes.

## Changed public symbol

Symbol: `django.core.validators.URLValidator`.

Change type: class-level regex behavior only. Constructor signature,
`__call__(value)`, error type, message, code, and scheme customization are
unchanged.

## Public callers

`django.forms.fields.URLField.default_validators` instantiates
`validators.URLValidator()`. Compatible: no call signature or return shape
changed.

`django.db.models.fields.URLField.default_validators` instantiates
`validators.URLValidator()`. Compatible: no call signature or return shape
changed.

Tests instantiate `URLValidator()` and `URLValidator(EXTENDED_SCHEMES)`.
Compatible: constructor behavior is unchanged.

## Behavioral compatibility

The intended behavior change is narrower acceptance of malformed userinfo.
Existing valid credential forms `userid@example.com` and
`userid:password@example.com` are preserved by proof obligation PO5. The visible
fixture with extra raw colons in userinfo is SUSPECT because it conflicts with
the public issue intent.
