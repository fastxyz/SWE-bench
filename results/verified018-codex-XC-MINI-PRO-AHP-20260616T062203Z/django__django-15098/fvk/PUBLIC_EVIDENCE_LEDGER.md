# Public Evidence Ledger

## E1: Reported Defect

- Source: `benchmark/PROBLEM.md`
- Quote: "Internationalisation didn't support language locale containing both script and region."
- Obligation: A language tag with both script and region is in domain for URL
  prefix detection.
- Status: Encoded in SPEC O1 and K claims `GLFP-SCRIPT-REGION-LOWER` and
  `GLFP-SCRIPT-REGION-BCP47`.

## E2: Concrete Expected Responses

- Source: `benchmark/PROBLEM.md`
- Quote: "The response of http://localhost:8000/en-latn-us/ and http://localhost:8000/en-Latn-US/ should be 200 U!."
- Obligation: Both lower-case and BCP 47 case URL prefixes must resolve to the
  i18n-patterned view when configured.
- Status: Encoded in SPEC O1, O2, O4, and integration proof obligation O5.

## E3: Configured Languages

- Source: `benchmark/PROBLEM.md`
- Quote: `LANGUAGES = [('en-us', ...), ('en-latn-us', ...), ('en-Latn-US', ...)]`
- Obligation: `settings.LANGUAGES` is an intended source for recognizing
  script-region language prefixes.
- Status: Encoded in SPEC O1 and K configured-language claims.

## E4: Regex Hazard

- Source: public hint in `benchmark/PROBLEM.md`
- Quote: "take settings.LANGUAGES into account somehow in get_language_from_path. Extending the regex might catch way too much non-language stuff."
- Obligation: The fix must avoid accepting arbitrary multi-hyphen path slugs
  through generic language fallback.
- Status: Encoded in SPEC O3 and K claim `GLFP-NO-ARBITRARY-THREE-PART`.

## E5: RFC 5646 Shape

- Source: `benchmark/PROBLEM.md`
- Quote: `langtag = language ["-" script] ["-" region] ...`
- Obligation: The language-script-region shape is a valid language tag shape.
- Status: Encoded in the valid-language precondition for the exact configured
  path segment.

## E6: Existing Source Contract

- Source: `repo/django/utils/translation/trans_real.py`
- Quote: "Return the language code if there's a valid language code found in `path`."
- Obligation: `get_language_from_path()` remains a path-to-language detector
  returning a language code or `None`.
- Status: Encoded in SPEC O1, O3, O4, and compatibility audit C1.
