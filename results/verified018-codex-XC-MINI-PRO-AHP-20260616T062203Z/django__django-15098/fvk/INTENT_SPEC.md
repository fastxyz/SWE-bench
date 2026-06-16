# Intent Spec

Status: constructed from public intent before accepting candidate behavior.

## Required Behavior

1. `i18n_patterns()` with `LocaleMiddleware` must accept a URL path whose first
   segment is a configured language tag containing both script and region, such
   as `en-latn-us`.

2. The same request path should work when the configured language tag and URL
   use BCP 47 case, such as `en-Latn-US`.

3. Language tags are path prefixes only when they are language candidates for
   Django's configured languages. The public hint warns that broadening the
   regex alone can catch non-language URL paths, so arbitrary multi-segment URL
   slugs must not become language prefixes merely through generic fallback.

4. Existing supported two-part language behavior should remain available:
   configured exact matches such as `en-us`, and existing legacy fallback
   behavior for the old regex's one optional segment, are outside the reported
   defect and should not be removed.

5. Public API shape must remain compatible. No caller should need a new
   argument or return type for `get_language_from_path()` or
   `LocalePrefixPattern.match()`.

## Domain

The audited domain is Django request path language-prefix detection for paths
beginning with `/`, and resolver prefix matching for the path string passed to
`LocalePrefixPattern.match()`. The issue's in-domain examples are:

- `/en-us/`
- `/en-latn-us/`
- `/en-Latn-US/`

Out of scope for this fix: changing translation catalog discovery,
`Accept-Language` negotiation, URL reversing output casing, or accepting
unconfigured language tags.
