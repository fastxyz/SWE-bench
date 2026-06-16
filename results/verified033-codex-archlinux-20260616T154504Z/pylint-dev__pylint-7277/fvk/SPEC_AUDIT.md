# Spec Audit

Status: constructed, not machine-checked.

| Formal item | Intent item | Result | Notes |
| --- | --- | --- | --- |
| C1 | I2, I3 | PASS | Directly captures the reported `runpy` failure mode. |
| C2 | I1, I2 | PASS | Keeps normal `python -m pylint` CWD stripping. |
| C3 | Domain safety | PASS | Stronger than the old implementation, but harmless and not used to justify hidden behavior. |
| C4 | I3, I4 | PASS | Preserves caller-owned first entry while still removing a CWD-like implicit `PYTHONPATH` slot. |
| C5 | I1, I4 | PASS | Matches the documented leading-colon cleanup when the first entry was a CWD marker. |
| C6 | I3, I4 | PASS | Preserves caller-owned first entry while still targeting the trailing implicit-CWD slot. |
| C7 | I1, I4 | PASS | Matches the documented trailing-colon cleanup when the first entry was a CWD marker. |
| C8 | I4 | PASS | Explicit `.` or `cwd` exceptions are documented in the docstring and public tests. |
| C9 | I5 | PASS | Prevents the proof from requiring a global CWD purge. |
| F-API | I6 | PASS | No public signature or call protocol changed. |
| F-ORDER | I3, I5 | PASS | Deletion preserves order of caller-provided and later entries. |

## Adequacy Result

The formal English is neither weaker nor stronger than the public intent for
the audited behavior. The only abstraction is `EnvCase`, which preserves the
branch distinctions that the implementation and public evidence use:
leading-implicit, trailing-implicit, explicit exception, and no relevant edge
colon. That abstraction does not collapse a passing and failing instance of the
reported bug: a first item of `"something"` and a first item of `cwd` remain
different in the model.
