# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 changes for:

- `django.utils.translation.trans_real.get_language_from_path()`
- `django.urls.resolvers.LocalePrefixPattern.match()`

There are no loops in the audited functions. The formal model uses a small
domain-specific mini-K fragment for path segment extraction, configured
language matching, legacy fallback, and locale prefix matching.

## Public Intent Ledger

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical obligations:

- E1/E2: configured language-script-region prefixes such as `/en-latn-us/`
  and `/en-Latn-US/` must resolve through `i18n_patterns()`.
- E3: `settings.LANGUAGES` is the public source that distinguishes configured
  language tags from ordinary URL slugs.
- E4: broad regex matching is suspect because it can catch non-language URL
  paths.
- E6: `get_language_from_path()` keeps returning a language code or `None`
  without changing its public signature.

## Formal Contract

O1. For a path beginning with `/`, if the first path segment is a well-formed
language code and exactly matches a configured language code, then
`get_language_from_path(path)` returns that configured code.

O2. If the first path segment is a well-formed language code and case-insensibly
matches a configured language code, then `get_language_from_path(path)` returns
the configured code selected by `settings.LANGUAGES` iteration order.

O3. A multi-hyphen first path segment that is not configured must not be
accepted by widening the legacy regex. It may only fall through to the legacy
one-optional-segment behavior, which does not parse a three-part slug such as
`de-simple-page`.

O4. Existing legacy behavior for old-domain prefixes remains delegated to
`get_supported_language_variant()` through the original regex when no exact
configured first-segment match exists.

O5. `LocalePrefixPattern.match(path)` accepts a path when the initial language
prefix is equal to `language_prefix` under ASCII case-insensitive comparison,
and removes exactly `len(language_prefix)` characters from the original path.

O6. API compatibility: no signature, return-type, or call-protocol changes are
introduced for the changed public symbols.

## Mini-K Artifacts

- `fvk/mini-django-i18n.k`: abstract operational semantics for the audited
  string/path operations.
- `fvk/django-i18n-spec.k`: K claims for O1 through O5.

The mini semantics keeps the property axes under audit: configured membership,
case-insensitive language matching, regex non-overmatch, and prefix stripping.
It abstracts away translation catalog lookup and URL reversing because the
issue intent does not require changing them.
