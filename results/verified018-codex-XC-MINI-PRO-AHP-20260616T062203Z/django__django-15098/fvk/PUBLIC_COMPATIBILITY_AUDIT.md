# Public Compatibility Audit

Status: static source audit, no execution.

## C1: `get_language_from_path(path, strict=False)`

- Public symbol: `django.utils.translation.trans_real.get_language_from_path`
- Compatibility status: pass
- Signature changed: no
- Return shape changed: no, still returns a language code or `None`
- Public wrapper: `django.utils.translation.get_language_from_path(path)` still
  delegates unchanged.
- Public callers inspected: `get_language_from_request()` and
  `LocaleMiddleware`.
- Compatibility note: V1 adds an earlier success branch for configured first
  path segments, then preserves the original regex and
  `get_supported_language_variant()` fallback path.

## C2: `LocalePrefixPattern.match(path)`

- Public symbol: `django.urls.resolvers.LocalePrefixPattern.match`
- Compatibility status: pass
- Signature changed: no
- Return shape changed: no, still returns `(remaining_path, (), {})` or `None`
- Public effect: only the comparison for the language prefix is now
  case-insensitive. Prefix stripping still uses the original prefix length and
  original path.
- Empty-prefix behavior: preserved because `path[:0].lower() == ""` is true,
  matching the old `path.startswith("")` behavior.

## C3: No Test File Edits

No tests were modified. Any test-removal recommendation remains conditioned on
machine-checking and is not applied.
