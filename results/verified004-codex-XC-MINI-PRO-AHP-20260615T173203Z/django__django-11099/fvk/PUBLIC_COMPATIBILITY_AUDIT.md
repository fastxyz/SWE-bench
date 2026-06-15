# Public Compatibility Audit

| ID | Changed symbol or surface | Public uses checked | Compatibility result |
| --- | --- | --- | --- |
| C-001 | `django.contrib.auth.validators.ASCIIUsernameValidator.regex` | Docs expose `ASCIIUsernameValidator`; public tests instantiate `validators.ASCIIUsernameValidator()`; example docs subclass `User` and set `username_validator = ASCIIUsernameValidator()`. | Compatible. Class name, constructor, message, code, inheritance, and `flags = re.ASCII` are unchanged. Only the accepted language is narrowed to match public intent by rejecting final LF. |
| C-002 | `django.contrib.auth.validators.UnicodeUsernameValidator.regex` | `AbstractUser.username_validator = UnicodeUsernameValidator()`; migrations reference `validators.UnicodeUsernameValidator()`; docs expose it as default validator. | Compatible. Class name, constructor, message, code, inheritance, `flags = 0`, and model integration are unchanged. No migration serialization shape changes because migrations instantiate the validator class, not a literal regex string. |
| C-003 | `django.core.validators.RegexValidator.__call__` | Used by both username validators and many unrelated validators. | No change. The audit rejected modifying `RegexValidator` globally because the public issue scopes the bug to the auth username validators and the same base class is shared widely. |

No public callsite or subclass override requires an additional update. No tests were modified.
