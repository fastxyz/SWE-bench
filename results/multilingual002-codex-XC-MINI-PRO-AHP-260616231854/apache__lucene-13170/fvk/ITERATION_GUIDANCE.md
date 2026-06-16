# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged. The FVK audit found the exact pre-fix counterexample described by
the issue and proved that V1's lower-middle midpoint discharges the helper safety
obligation for the modeled defect.

## Source Changes

No additional source edits are justified by the findings.

- F-001 is fixed by the existing V1 expression change.
- F-002 is discharged by the helper invariant and branch-preservation proof.
- F-003 shows no public compatibility issue.
- F-004 records that broader return-offset semantics are outside this issue's proven
  exception-safety model and are preserved by V1.

## Recommended Follow-Up Outside This Benchmark

When a normal execution environment and test-edit permission are available:

- run the emitted `kompile` and `kprove` commands from `PROOF.md`;
- run the relevant Lucene test suite;
- add a regression test for `sentenceStarts.length == 2` and `preceding` called in or
  after the second sentence;
- keep integration tests that cover OpenNLP model loading, `CharacterIterator`, and
  returned offsets because this FVK proof abstracts those pieces.

## Stop Condition

The FVK package justifies `V2 == V1` for the requested source fix. No hidden/evaluator
signal was used.

