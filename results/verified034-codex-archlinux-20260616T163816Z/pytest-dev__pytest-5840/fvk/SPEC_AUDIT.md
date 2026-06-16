# Spec Audit

| Formal English entry | Intent entry | Verdict | Notes |
| --- | --- | --- | --- |
| UNIQUE-PATH-PRESERVES-CASE | Required behavior 1 and 3 | Pass | Directly matches the issue/hint and helper docstring. |
| UNIQUE-PATH-ALIASES | Required behavior 2 | Pass | Matches the `_importconftest` symlink comment and existing conftest tests. |
| IMPORT-CONFTEST-PATH | Required behavior 1 | Pass | Connects the helper result to the observed `pyimport()` failure path. |
| Frame conditions | Required behavior 3 and 4 | Pass | V1 preserves signature and returns `type(path)(...)`. |
| External `Path.resolve()` filesystem behavior | Domain assumption | Ambiguous but explicit | The mini semantics cannot prove OS/pathlib casing. It is recorded as PO-2 and FINDING F2, and is justified by public hint plus the helper docstring. |

No formal-English entry is candidate-derived without public evidence. The only
unproved part is the external filesystem/pathlib behavior, which is a trusted
base obligation rather than a pytest source-code defect.
