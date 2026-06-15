# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Symbol

`django.template.library.parse_bits()`

- Signature changed: no.
- Return shape changed: no.
- Exception classes changed: no. The change affects which existing
  `TemplateSyntaxError` message is selected for the reported keyword-only cases.

## Call Sites

| Caller | Evidence | Compatibility result |
| --- | --- | --- |
| `Library.simple_tag()` | `repo/django/template/library.py:119-122` | Pass. Same call signature and same returned `(args, kwargs)` shape. |
| `Library.inclusion_tag()` | `repo/django/template/library.py:152-155` | Pass. Same call signature and same returned `(args, kwargs)` shape. |
| `InclusionAdminNode.__init__()` | `repo/django/contrib/admin/templatetags/base.py:16-18` | Pass. Same call signature. Behavior improves for the same keyword-only validation shape if such a tag is used. |

## Public Behavior Compatibility

- Existing unknown keyword diagnostics remain intact.
- Existing missing required keyword-only diagnostics remain intact.
- Existing support for `**kwargs` remains intact.
- No public override or subclass signature is affected because no method
  signature changed and no new keyword is passed through virtual dispatch.
