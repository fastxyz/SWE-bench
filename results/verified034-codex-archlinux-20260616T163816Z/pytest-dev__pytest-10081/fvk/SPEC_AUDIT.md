# Spec Audit

Status: constructed, not machine-checked.

| Formal English Entry | Intent Entries | Result | Notes |
| --- | --- | --- | --- |
| K-CLAIM-CLASS-SKIP | I-001, I-002, I-003 | PASS | Directly captures the reported class-level skip teardown bug. |
| K-CLAIM-METHOD-SKIP | I-004 | PASS | Preserves the already-covered method-level skip behavior. |
| K-CLAIM-PDB-NONSKIPPED | I-005 | PASS | Preserves intentional `--pdb` delayed teardown for tests that are not skipped. |
| K-CLAIM-NO-PDB-NONSKIPPED | I-003, E-002 | PASS | Confirms V1 does not change non-`--pdb` behavior. |
| K-PRED-SHOULD-DELAY | I-002, I-004, I-005, D-001 | PASS | Adds class/instance skip to the existing method-skip guard without weakening non-skipped behavior. |
| K-FRAME-COMPATIBILITY | Public compatibility audit | PASS | V1 changes only an internal condition; no public API or virtual dispatch shape changes. |

No formal-English entry is candidate-derived without public evidence. The class-skip postcondition is issue-derived; the non-skipped delayed teardown frame is public-test and source-comment derived.
