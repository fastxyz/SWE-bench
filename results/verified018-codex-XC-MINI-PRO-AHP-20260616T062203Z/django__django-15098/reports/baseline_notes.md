# Baseline Notes

## Root Cause

`django.utils.translation.trans_real.get_language_from_path()` used
`language_code_prefix_re`, which only recognizes a base language plus one
optional `-` or `@` segment. A locale such as `en-latn-us` has both a script
and a region segment, so it was not extracted from the request path before
language validation.

Simply widening that regex would make unrelated URL prefixes look like language
codes. For example, the existing fallback behavior can reduce a parsed
`de-simple-page` candidate to `de`, so a broader regex would risk treating
ordinary URL paths as language prefixes.

BCP 47 language tags are also case-insensitive. Even after recognizing a
configured `en-Latn-US` path prefix, Django's active language value is
normalized through `to_language()`, so URL prefix matching also needed to avoid
case-sensitive rejection of the same language tag.

## Changed Files

`repo/django/utils/translation/trans_real.py`

Added an exact configured-language check at the start of
`get_language_from_path()`. The first path segment is accepted when it is a
well-formed language code and matches a key in `settings.LANGUAGES`, including
case-insensitive matches. This handles configured language-script-region tags
without broadening the existing fallback regex.

`repo/django/urls/resolvers.py`

Changed `LocalePrefixPattern.match()` to compare the language prefix
case-insensitively while preserving the original slice length used to remove
the prefix. This lets paths such as `en-Latn-US/` match an active language
prefix normalized as `en-latn-us/`.

## Assumptions and Rejected Alternatives

I assumed the intended behavior is to accept language-script-region tags when
they are explicitly present in `settings.LANGUAGES`, because the issue and
public hints focus on configured custom locales rather than arbitrary BCP 47
subtags in every URL.

I rejected changing `language_code_prefix_re` to allow unlimited or two hyphen
segments because it would parse URL prefixes such as `/de-simple-page/` as a
language candidate and then allow existing generic fallback logic to resolve
that candidate to `de`.

I rejected changing global language normalization to preserve BCP 47 casing
because that would affect translation state and output broadly. A
case-insensitive comparison in the locale URL prefix is narrower and follows
the case-insensitive nature of language tags.
