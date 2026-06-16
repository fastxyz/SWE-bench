# Baseline Notes

## Root cause

The `regexp_csv` option transformer in `repo/pylint/config/argument.py` reused the generic comma-separated-value parser. That parser splits every comma before compiling the resulting strings as regular expressions. Regex quantifiers such as `{1,3}` also contain commas, so a valid value like `(foo{1,3})` was split into invalid fragments before compilation.

## Changed files

- `repo/pylint/config/argument.py`: Added a regex-aware splitter for `regexp_csv` values. It preserves commas while a `{...}` quantifier is open, inside a character class, or escaped, but still splits on commas between separate regex entries. `_regexp_csv_transfomer` now uses this splitter and continues to compile each result through `_regex_transformer`, preserving existing clean `ArgumentTypeError` handling for invalid regexes.
- `reports/baseline_notes.md`: Added this report with the required root-cause analysis and implementation notes.

## Assumptions and alternatives

- I assumed the intended short-term compatibility behavior is to keep comma-separated lists of regexes, because several existing options use `type: regexp_csv`.
- I assumed the issue should at least be fixed for regex quantifier commas, matching the public discussion about not splitting while inside an unclosed `{`. I also treated escaped commas and commas in character classes as regex syntax so users have an explicit way to express a literal comma.
- I considered changing `regexp_csv` to treat the entire value as one regex, but rejected it because that would break existing configurations that intentionally provide multiple regexes separated by commas.
- I considered changing the generic CSV parser, but rejected it because non-regex options do not need regex syntax awareness and changing them would expand the behavioral surface unnecessarily.
- I did not run tests or execute code, per the task constraints.
