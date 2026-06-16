# Intent Spec

Status: constructed from public evidence only; not machine-checked.

Target:
- `repo/pylint/config/argument.py::_split_regex_csv`
- `repo/pylint/config/argument.py::_regexp_csv_transfomer`

Required behavior:

1. `regexp_csv` options must continue to support comma-separated lists of regex patterns. This follows from option names and help text such as "regexes, separated by a comma" and the public discussion that removing CSV behavior would be a breaking change.
2. A comma that is part of regex syntax must not be treated as a list separator. The issue example `(foo{1,3})` is a valid regex and must be passed to regex compilation as one pattern, not split into `(foo{1` and `3})`.
3. Users need a way to express literal commas in regexes. The issue explicitly allows "adding some way to escape commas"; regex escaping with `\,` is the intended public-compatible mechanism.
4. Existing generic CSV behavior should be preserved for `regexp_csv` outside regex syntax: top-level unescaped commas separate entries, entries are stripped, empty entries are discarded, order is preserved.
5. Invalid individual regexes should fail cleanly through Pylint's argument parser as `argparse.ArgumentTypeError`, not leak raw `re.error` tracebacks.
6. The fix should remain scoped to regex-list option parsing. Non-regex CSV options and path-specific regex CSV parsing are not part of this issue unless independently justified.

Out of scope / ambiguity:

- The issue configuration snippet spells `bad-name-rgxs`, while the issue title, docs, and source option use `bad-names-rgxs`. This audit treats the snippet as a typo and does not add a new alias.
- Deprecating `regexp_csv` options may be a future design decision, but the public discussion says keeping compatibility is acceptable for this short-term fix.
