# Spec Audit

Status: adequacy check, constructed and not machine-checked.

| Formal item | Intent item | Result | Notes |
| --- | --- | --- | --- |
| C1 mixed string/Path duplicate raises duplicate error | Intent 2 and 3 | Pass | Directly matches the reported issue. |
| C2 reversed mixed Path/string duplicate raises duplicate error | Intent 2 and 3 | Pass | Covers list order symmetry for the same equality problem. |
| C3 Path app default fixture directory raises default-directory error | Intent 4 | Pass | Follows from public duplicate-prevention release note and existing public test for string default paths. |
| C4 nonduplicate Path entry remains accepted | Intent 1 and 5 | Pass | Preserves existing public Path loading behavior. |
| C5 checks operate on filesystem strings | Intent 2 | Pass | `os.fspath()` is the minimal path-like normalization required by the issue. |
| Exclusion of realpath-level alias duplicates | Intent "explicitly not settled" | Ambiguous | The code later canonicalizes search dirs with `realpath()`, but the public issue only requires path-like comparison. This is Finding F-002, not a blocker for V1. |
| No API/search-order change | Intent 6 | Pass | V1 changes only a local normalization step before existing validation. |

## Adequacy conclusion

The formal claims are neither weaker nor stronger than the path-like duplicate
behavior required by the issue. The only ambiguity is the broader
canonical-alias question, which the spec leaves out of the proof and records in
`FINDINGS.md` instead of treating as evidence for a new source edit.
