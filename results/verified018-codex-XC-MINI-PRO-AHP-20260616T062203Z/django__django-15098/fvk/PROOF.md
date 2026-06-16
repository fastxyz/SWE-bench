# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, or `kprove`
commands were executed.

## What Is Proved

For the audited repair surface, the constructed proof establishes partial
correctness of these properties:

- configured language-script-region path prefixes are returned by
  `get_language_from_path()`;
- configured language matching is case-insensitive when needed;
- non-configured three-part slugs do not become language prefixes through a
  broadened regex;
- locale prefix matching is case-insensitive and strips the original prefix
  length;
- empty-prefix resolver behavior is preserved.

## Proof Sketch

### `getLanguageFromPath`

1. Start in a configuration whose `<k>` cell contains
   `getLanguageFromPath(PATH, LANGS)`.
2. If `PATH` has a leading slash, `firstPathSegment(PATH)` is a valid language
   code, and `configuredCaseMatch(firstPathSegment(PATH), LANGS)` is true, the
   exact configured-language rule fires.
3. The result is
   `lang(configuredCaseValue(firstPathSegment(PATH), LANGS))`.
4. For `/en-latn-us/` under `issueLangs()`, simplification rewrites the first
   segment to `en-latn-us` and the configured value to `en-latn-us`.
5. For `/en-Latn-US/` under `issueLangs()`, simplification rewrites the first
   segment to `en-Latn-US` and the configured value to `en-Latn-US`.
6. For `/en-Latn-US/` under `lowerOnlyLangs()`, simplification rewrites the
   configured value to `en-latn-us`, proving the case-insensitive configured
   match.
7. If the configured first-segment branch is false, the second rule delegates
   to `legacyLanguageFromPath(PATH, LANGS)`. For `/de-simple-page/` under
   `germanOnlyLangs()`, simplification gives
   `configuredCaseMatch(...) == false` and
   `legacyPrefixRegexMatches(...) == false`, so the result is `none`.

There are no loops or recursive calls; no circularity is needed.

### `localePrefixMatch`

1. Start in a configuration whose `<k>` cell contains
   `localePrefixMatch(PATH, PREFIX)`.
2. If `ciStartsWith(PATH, PREFIX)` is true, the match rule fires and returns
   `match(PREFIX, dropPrefixLength(PATH, PREFIX))`.
3. For `PATH = "en-Latn-US/"` and `PREFIX = "en-latn-us/"`, simplification
   proves the case-insensitive prefix check and the empty remainder.
4. For `PREFIX = ""`, simplification proves that the old empty-prefix behavior
   remains: every path matches and the remainder is the original path.

There are no loops or recursive calls; no circularity is needed.

## Adequacy Check

`fvk/SPEC_AUDIT.md` marks each formal claim as passing against
`fvk/INTENT_SPEC.md`. The claims are not derived from V1 alone: the exact
configured-language branch comes from the issue's `LANGUAGES` example and
public hint, while the case-insensitive resolver claim comes from the issue's
BCP 47 case example and Django's active-language normalization.

## Residual Risk

- The proof is constructed, not machine-checked.
- The mini semantics is property-complete for the changed behavior, but it is
  not a full Python or full Django semantics.
- Termination is trivial for the modeled straight-line rules and not separately
  proved.
- Existing fallback internals are represented by `legacyLanguageFromPath()`;
  V1 preserves that code path but this focused proof does not re-prove all
  legacy language fallback behavior.

## Machine-Check Commands Not Run

These commands are written for a later environment with K installed:

```sh
kompile fvk/mini-django-i18n.k --backend haskell
kast --backend haskell fvk/django-i18n-spec.k
kprove fvk/django-i18n-spec.k
```

Expected outcome if the model and claims parse as written: `kprove` reduces
the claims to `#Top`.

## Test Guidance

No tests were edited. Because the proof is not machine-checked and the benchmark
uses hidden tests, no test-removal recommendation is made. Tests for the issue
examples `/en-latn-us/` and `/en-Latn-US/`, plus a non-overmatch case such as
`/de-simple-page/`, would be useful public tests if test editing were allowed.
