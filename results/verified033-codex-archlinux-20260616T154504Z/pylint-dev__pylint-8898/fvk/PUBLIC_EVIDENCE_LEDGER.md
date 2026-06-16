# Public Evidence Ledger

Status: constructed from public evidence only; not machine-checked.

| Id | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E1 | issue | "Since pylint splits on commas in this option ... if there are any commas in the regular expression, the result is mangled" | Do not split regex-internal commas as CSV separators. | Encoded in SPEC and K claims. |
| E2 | issue | `bad-name-rgxs = "(foo{1,3})"` and expected "any valid regular expression to be expressible" | `(foo{1,3})` must remain one regex string before compilation. | Encoded in O6 / REGEX-QUANTIFIER-EXAMPLE. |
| E3 | issue | "If not directly, adding some way to escape commas" | Escaped comma `\,` must not be a separator. | Encoded in O3 / REGEX-ESCAPED-COMMA. |
| E4 | public hints | "Changing that would be a major break for many options" | Preserve comma-separated list behavior outside regex syntax. | Encoded in O7 / REGEX-TOPLEVEL-CSV. |
| E5 | public hints | "not splitting on a comma if it's inside an unclosed `{`" | Scanner must track brace context and suppress separator recognition while open. | Encoded in O2/O6. |
| E6 | source/help text | `good-names-rgxs` and `bad-names-rgxs` use `type: "regexp_csv"` and help says "separated by a comma" | Keep ordered sequence of regex patterns as the return shape for `regexp_csv`. | Encoded in O4/O7/O8. |
| E7 | source | `_regex_transformer` catches `re.error` and raises `argparse.ArgumentTypeError` | Invalid regex fragments must use the clean argparse error path. | Encoded in O9. |
| E8 | public test | `test_csv_regex_error` expects `--bad-names-rgx=(foo{1,3})` to error after splitting | SUSPECT legacy-test obligation: it asserts the behavior reported as the bug. | Recorded as F-001; not used as spec. |
| E9 | source/API | `_regexp_csv_transfomer` is private and registered under existing `"regexp_csv"` type key | Public option API shape should not change. | Encoded in O10 and compatibility audit. |
