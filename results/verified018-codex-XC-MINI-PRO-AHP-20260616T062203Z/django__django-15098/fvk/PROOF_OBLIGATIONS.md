# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Exact Configured Script-Region Prefix

- Claim: If a request path starts with `/` and its first segment is a valid
  language code exactly present in `settings.LANGUAGES`, then
  `get_language_from_path()` returns that configured language code.
- Evidence: E1, E2, E3.
- Source discharge: V1 checks `path.startswith('/')`, extracts
  `path[1:].split('/', 1)[0]`, validates with `language_code_re`, and returns
  `lang_code` when it is in `get_languages()`.
- K claim: `GLFP-SCRIPT-REGION-LOWER` and `GLFP-SCRIPT-REGION-BCP47`.
- Status: discharged by construction.

## PO2: Case-Insensitive Configured-Language Prefix

- Claim: If the first path segment case-insensibly matches a configured
  language code, then `get_language_from_path()` returns the configured code
  selected by `settings.LANGUAGES` iteration order.
- Evidence: E2, E5.
- Source discharge: V1 computes `lower_lang_code = lang_code.lower()` and
  compares each string key in `get_languages()` by `.lower()`.
- K claim: `GLFP-SCRIPT-REGION-CASE-INSENSITIVE`.
- Status: discharged by construction.

## PO3: No Regex-Only Overmatch for Three-Part Slugs

- Claim: A non-configured three-part URL slug such as `/de-simple-page/` must
  not be accepted as a language prefix through generic fallback.
- Evidence: E4.
- Source discharge: V1 does not broaden `language_code_prefix_re`; when exact
  configured matching fails, the original regex still rejects
  `/de-simple-page/`.
- K claim: `GLFP-NO-ARBITRARY-THREE-PART`.
- Status: discharged by construction.

## PO4: Preserve Legacy One-Optional-Segment Fallback

- Claim: Paths outside the exact configured first-segment branch continue to use
  the existing `language_code_prefix_re` plus `get_supported_language_variant()`
  behavior.
- Evidence: E6 and compatibility C1.
- Source discharge: V1 falls through to the unchanged original regex and
  `get_supported_language_variant(lang_code, strict=strict)` block.
- K representation: `legacyLanguageFromPath(PATH, LANGS)`.
- Status: discharged by construction for delegation shape; full behavior is
  inherited from existing code and not re-proved in this focused model.

## PO5: Case-Insensitive Resolver Prefix Match

- Claim: `LocalePrefixPattern.match()` accepts a path whose prefix differs from
  `language_prefix` only by case and strips exactly the prefix length.
- Evidence: E2, E5, implementation fact that `to_language()` normalizes active
  language case.
- Source discharge: V1 compares
  `path[:len(language_prefix)].lower() == language_prefix.lower()` and returns
  `path[len(language_prefix):], (), {}`.
- K claim: `LOCALE-MATCH-BCP47-CASE`.
- Status: discharged by construction.

## PO6: Empty Prefix Compatibility

- Claim: When `language_prefix == ""`, `LocalePrefixPattern.match()` still
  matches all paths and returns the original path as the remainder.
- Evidence: compatibility C2.
- Source discharge: `path[:0].lower() == "".lower()` is true and
  `path[0:]` is the original path.
- K claim: `LOCALE-MATCH-DEFAULT-EMPTY`.
- Status: discharged by construction.

## PO7: Public API Compatibility

- Claim: No changed symbol requires caller updates.
- Evidence: C1, C2.
- Source discharge: signatures and return shapes are unchanged.
- K claim: not applicable; static compatibility obligation.
- Status: discharged by static audit.
