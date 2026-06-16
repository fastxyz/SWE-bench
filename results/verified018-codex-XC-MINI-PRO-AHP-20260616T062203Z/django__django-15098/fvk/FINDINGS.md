# Findings

Status: FVK audit findings for V1, constructed and not machine-checked.

## F1: V1 Fixes the Reported Lower-Case Script-Region Prefix

- Input: `/en-latn-us/` with `LANGUAGES` containing `en-latn-us`.
- Pre-fix observed behavior from issue: 404.
- Expected behavior from public intent: 200 response through the
  `i18n_patterns()` view.
- V1 audit result: `get_language_from_path()` recognizes the first segment as
  an exact configured language code before reaching the legacy regex.
- Proof obligations: PO1.
- Classification: fixed code bug.

## F2: V1 Fixes the Reported BCP 47 Case Prefix

- Input: `/en-Latn-US/` with `LANGUAGES` containing `en-Latn-US`.
- Pre-fix observed behavior from issue: 404.
- Expected behavior from public intent: 200 response through the
  `i18n_patterns()` view.
- V1 audit result: `get_language_from_path()` recognizes the configured cased
  tag, and `LocalePrefixPattern.match()` compares the active prefix
  case-insensitively after activation normalizes the language value.
- Proof obligations: PO1, PO5.
- Classification: fixed code bug.

## F3: V1 Avoids the Regex-Only Overmatch Hazard

- Input: `/de-simple-page/` with `LANGUAGES` containing `de` but not
  `de-simple-page`.
- Risk if using a broadened regex: the parsed candidate could fall back to
  `de`, treating a normal URL slug as a language prefix.
- Expected behavior from public hint: do not catch too much non-language path
  text.
- V1 audit result: exact configured-language matching fails and the unchanged
  old regex still rejects the three-part slug.
- Proof obligations: PO3.
- Classification: confirmed guard against an alternative-fix regression.

## F4: Legacy Fallback Is Preserved by Delegation, Not Re-Proved

- Input class: old-domain one-optional-segment prefixes such as `/de-ch/`.
- Expected behavior: preserve existing `get_supported_language_variant()`
  fallback behavior outside the new exact configured-language branch.
- V1 audit result: the original regex and fallback block remain unchanged.
- Proof obligations: PO4.
- Classification: confirmed compatibility, with focused-model boundary.

## F5: No Additional Source Change Required After FVK

- Input class: the full issue reproduction path through `LocaleMiddleware` and
  `LocalePrefixPattern`.
- Expected behavior: configured script-region prefixes resolve to the view;
  arbitrary non-configured slugs are not newly treated as language prefixes.
- V1 audit result: PO1 through PO7 cover the intended behavior. No uncovered
  public-intent obligation requires changing V1.
- Proof obligations: PO1, PO2, PO3, PO4, PO5, PO6, PO7.
- Classification: V1 stands.

## Proof-Derived Findings From `/verify`

- The constructed proof has not been machine-checked. This is not a code bug,
  but test removal and proof confidence remain conditioned on running the
  emitted K commands.
- The mini semantics abstracts legacy fallback as `legacyLanguageFromPath()`.
  That is deliberate because the FVK target is the V1 repair surface; full
  re-verification of Django's existing language variant fallback is outside the
  public issue and unchanged by V1.
