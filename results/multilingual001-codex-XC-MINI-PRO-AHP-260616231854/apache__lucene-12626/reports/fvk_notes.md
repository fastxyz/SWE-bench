# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found that the V1 source edit exactly discharges the
issue-backed obligation and does not create a compatibility or frame-condition problem.

## Trace to Findings and Proof Obligations

`fvk/FINDINGS.md` FVK-001 identifies the root bug: pre-V1 `SegmentInfos.replace` copied the segment
list and `lastGeneration` but left `userData` unchanged. `fvk/PROOF_OBLIGATIONS.md` PO-3 states the
corresponding proof obligation: after `replace(other)`, receiver `userData` must equal
`other.userData`. The V1 assignment in
`repo/lucene/core/src/java/org/apache/lucene/index/SegmentInfos.java` discharges that obligation.

I did not add a defensive copy. `fvk/FINDINGS.md` FVK-002 records that alternative and rejects it:
the public issue's proposed fix uses direct assignment, `readMapOfStrings()` returns immutable maps
for the explicit-commit path, and existing commit-data methods store references directly. PO-3 only
requires the replacement commit metadata to become the receiver metadata; it does not require a new
copy policy.

I did not change generation, version, or counter behavior. PO-5 records the frame condition from
the method comment: `replace` keeps write-once metadata. V1 only adds the missing `userData`
assignment, so those fields remain preserved.

I did not change any public API, signature, serialization format, or tests. PO-6 records that
compatibility obligation, and the V1 edit is internal to a package-private method. No test files
were modified.

## Verification Status

The FVK proof is constructed, not machine-checked. The benchmark forbids running K tooling, tests,
Python, or project code, so `kompile`, `kast`, `kprove`, and the Lucene test suite were not run.
The exact commands are recorded in `fvk/SPEC.md` and `fvk/PROOF.md` for a later environment.
