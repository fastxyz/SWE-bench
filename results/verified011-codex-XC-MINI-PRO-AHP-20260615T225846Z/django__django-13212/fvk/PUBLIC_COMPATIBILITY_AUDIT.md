# Public Compatibility Audit

Status: no compatibility blocker found by source inspection.

Changed public symbols:

- `django.core.validators.RegexValidator.__call__`
- `django.core.validators.URLValidator.__call__`
- `django.core.validators.EmailValidator.__call__`
- `django.core.validators.validate_ipv4_address`
- `django.core.validators.validate_ipv6_address`
- `django.core.validators.validate_ipv46_address`
- `django.core.validators.DecimalValidator.__call__`
- `django.core.validators.FileExtensionValidator.__call__`
- `django.core.validators.ProhibitNullCharactersValidator.__call__`
- `django.contrib.postgres.validators.KeysValidator.__call__`

Compatibility facts:

- No function or method signature changed.
- No caller must pass new arguments.
- `ValidationError` already accepts `params`.
- Existing messages and codes are preserved.
- Existing specialized params are preserved and extended.
- Consumers that ignore `params` continue to behave as before.
- Consumers with custom messages containing `%(value)s` now get the requested
  interpolation value.

Out-of-scope compatibility boundary:

Password validators were not changed because exposing the raw password through
`params['value']` would need explicit public intent and security review.
