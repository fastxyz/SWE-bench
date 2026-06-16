# Spec Audit

| Formal claim | Intent coverage | Verdict |
| --- | --- | --- |
| QS-EXISTING-ROOT | Matches I1, I2, I4, and I5: selected root already contains `conf.py`; command exits status 1 and does not generate. | PASS |
| QS-EXISTING-SOURCE | Matches I1 and I3: `source/conf.py` is a separate-source existing project and receives the same no-overwrite treatment. | PASS |
| QS-EXISTING-ROOT / QS-EXISTING-SOURCE no `replacementPrompt` | Matches I4 and I5: the legacy prompt is the reported failure surface and the public hint asks for immediate exit. | PASS |
| QS-NO-CONF-FRAME | Matches I6 only as a reduced frame condition; the full questionnaire is not re-proved. | PASS WITH SCOPE NOTE |

## Adequacy conclusion

The formal claims are neither weaker nor stronger than the adopted public
intent for the audited branch. The only apparent tension is between the issue's
"After pressing Enter" wording and the public hint's "exit with status 1
immediately." The ledger resolves that by treating the old replacement prompt as
SUSPECT legacy UI because it is part of the described bug, not a requirement to
preserve.
