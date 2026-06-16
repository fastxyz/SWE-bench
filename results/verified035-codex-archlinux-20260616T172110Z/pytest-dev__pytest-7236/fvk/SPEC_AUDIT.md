# Spec Audit

Status: constructed, not machine-checked.

| Formal obligation | Intent item | Result | Reason |
|---|---|---|---|
| `SKIPPED-UNDER-PDB` | I-1 | pass | It states the exact issue intent: if unittest does not reach teardown for a skipped method, pytest performs no delayed teardown call. |
| `REACHED-TEARDOWN-UNDER-PDB` | I-2 | pass | It preserves the public delayed-teardown behavior for tests that do reach unittest teardown. |
| `NO-PDB-NO-DELAYED-CALL` | I-3 | pass | It frames the regression to `--pdb` and ensures this patch does not add delayed teardown outside pdb mode. |
| Public API compatibility | I-4 | pass | No public function, method, class, result callback, or hook signature is changed. |
| Scope and limits | I-5 | pass | The formal model explicitly covers teardown scheduling only and does not claim full pytest or CPython verification. |

No formal-English obligation is weaker than the public intent for the reported
bug. No obligation preserves the buggy V1-predecessor behavior.
