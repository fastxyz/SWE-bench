# Public Evidence Ledger

| ID | Source | Quoted evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | `benchmark/PROBLEM.md` | "The intent is to only allow alphanumeric characters as well as ., @, +, and -." | Allowed-character postcondition for both validators. | Encoded in I-001, I-002, PO-001. |
| E-002 | `benchmark/PROBLEM.md` | "`$` will also match a trailing newline. Therefore, the user name validators will accept usernames which end with a newline." | A final newline is outside the valid language and must be rejected. | Encoded in I-003, PO-002, F-001. |
| E-003 | `benchmark/PROBLEM.md` | "using `\A` and `\Z` to terminate regexes" and example `r'\A[\w.@+-]+\Z'` | Absolute string anchors are the intended repair. | Encoded in PO-003 and the V1 source. |
| E-004 | `benchmark/PROBLEM.md` | "using the regex above in the two validators in contrib.auth.validators" | Scope is the two auth username validators. | Encoded in I-005 and compatibility audit C-001. |
| E-005 | `repo/docs/ref/contrib/auth.txt` | "A field validator allowing only ASCII letters and numbers, in addition to `@`, `.`, `+`, `-`, and `_`." | ASCII validator allowed set includes ASCII letters/numbers/underscore plus punctuation. | Encoded in I-001, PO-004. |
| E-006 | `repo/docs/ref/contrib/auth.txt` | "A field validator allowing Unicode characters, in addition to `@`, `.`, `+`, `-`, and `_`." | Unicode validator allowed set includes Unicode word characters plus punctuation. | Encoded in I-002, PO-005. |
| E-007 | `repo/django/core/validators.py` | `regex_matches = self.regex.search(str(value))` | Because `search()` is used, the validator regex itself must enforce full-string matching. | Encoded as implementation evidence in PO-003. |
| E-008 | `repo/django/contrib/auth/validators.py` | `flags = re.ASCII` and `flags = 0` | ASCII and Unicode validators differ only in regex flags. | Encoded in PO-004 and PO-005. |
| E-009 | `repo/tests/auth_tests/test_validators.py` | Valid examples include `joe`, `Rene` with accent, and Arabic; invalid examples include apostrophe, space, zero-width space, non-breaking space, en dash. | Public tests support the documented character-family boundary but do not cover trailing newline. | Supporting evidence only; not an oracle. |
| E-010 | `repo/docs/releases/1.8.3.txt` | "didn't prohibit newline characters (due to the usage of `$` instead of `\Z` in the regular expressions)" | Django has prior public documentation that `$` is the wrong validator terminator for newline-sensitive validation. | Supporting evidence for PO-002 and PO-003. |
