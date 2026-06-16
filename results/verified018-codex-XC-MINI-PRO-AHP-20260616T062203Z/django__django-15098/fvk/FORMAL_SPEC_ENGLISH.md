# Formal Spec English

Status: paraphrase of the K claims, constructed and not machine-checked.

## Claims

`GLFP-SCRIPT-REGION-LOWER`

For the issue language map, `getLanguageFromPath("/en-latn-us/")` reaches
`lang("en-latn-us")`.

`GLFP-SCRIPT-REGION-BCP47`

For the issue language map, `getLanguageFromPath("/en-Latn-US/")` reaches
`lang("en-Latn-US")` because that exact cased tag is configured.

`GLFP-SCRIPT-REGION-CASE-INSENSITIVE`

For a configured language map that contains only `en-latn-us`, a path segment
spelled `en-Latn-US` reaches `lang("en-latn-us")` through case-insensitive
configured-language matching.

`GLFP-NO-ARBITRARY-THREE-PART`

For a language map containing only `de`, the path `/de-simple-page/` reaches
`none`; the three-part slug is not converted to `de` by generic fallback.

`LOCALE-MATCH-BCP47-CASE`

`localePrefixMatch("en-Latn-US/", "en-latn-us/")` reaches
`match("en-latn-us/", "")`, meaning the comparison succeeds
case-insensitively and strips the prefix length from the original path.

`LOCALE-MATCH-DEFAULT-EMPTY`

`localePrefixMatch("anything/", "")` reaches `match("", "anything/")`,
preserving the old empty-prefix behavior used when the default language is not
prefixed.

## Frame Conditions

The formal model does not change `get_supported_language_variant()` semantics.
When the exact configured first-segment branch does not apply, the function is
specified to delegate to the legacy path-prefix detector.

The formal model does not change URL reversing. It covers only path matching,
which is the request-resolution path implicated by the issue.
