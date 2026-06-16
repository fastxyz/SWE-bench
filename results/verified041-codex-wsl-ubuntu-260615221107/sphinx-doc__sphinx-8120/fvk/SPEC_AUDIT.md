# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent entries | Audit | Notes |
| --- | --- | --- | --- |
| `PROJECT-OVERRIDES` | I-1, I-2, E-1 through E-5 | PASS | The claim states the issue's required override behavior directly. |
| `PROJECT-ORDER` | I-4, E-5, E-6 | PASS | `locale_dirs` is a path-like ordered configuration; `locale.init()` order is the implementation mechanism. |
| `BUILTIN-FALLBACK` | I-3, I-5, E-8 | PASS | This preserves fallback for missing project messages and preserves the old system-before-package order. |
| `PACKAGE-FALLBACK` | I-3, I-5, E-8 | PASS | This preserves bundled translations when project and system catalogs do not answer. |
| `NO-PROJECT-PRESERVES-OLD-BUILTINS` | I-5, E-8 | PASS | V1 does not alter projects without yielded locale dirs. |
| Compatibility audit | I-6, E-9 | PASS | No public signatures or extension catalog call paths changed. |

No formal-English obligation is candidate-derived without public support. The
only implementation-derived fact used as a frame condition is the built-in
system-before-package order, which V1 preserves rather than expands.
