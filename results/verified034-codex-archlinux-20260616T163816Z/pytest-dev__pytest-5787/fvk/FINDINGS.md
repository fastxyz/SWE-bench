# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and proof-obligation construction only.

## F-001: Original serialization dropped earlier chained exceptions

Classification: code bug, fixed by V1 and retained in V2.

Evidence: E-001 through E-006 in `fvk/SPEC.md`.

Input: a report whose `longrepr` is an `ExceptionChainRepr` with three elements,
for example `ValueError(11)` causing `ValueError(12)` causing `ValueError(13)`.

Observed pre-fix behavior: `_to_json` serialized only
`longrepr.reprtraceback` and `longrepr.reprcrash`. For
`ExceptionChainRepr`, those fields intentionally point to the newest exception
only, so `_from_json` rebuilt a single `ReprExceptionInfo` and terminal output
showed only the last exception.

Expected behavior: serialization must preserve every chain element and each
connecting direct-cause/context description so the receiving process can render
the complete chain.

Resolution: `_serialize_exception_longrepr` records a `chain` list for actual
multi-exception chains, and `_deserialize_exception_longrepr` reconstructs an
`ExceptionChainRepr` from it. Covered by PO-004 and PO-005.

## F-002: V1 changed ordinary single-exception report round trips

Classification: compatibility bug in V1, fixed in V2.

Evidence: E-007 and E-008 in `fvk/SPEC.md`.

Input: a normal failed test with a single exception. Pytest creates an
`ExceptionChainRepr` with one chain element, even though there is no chained
exception to preserve.

Observed V1 behavior: V1 serialized a `chain` field for every
`ExceptionChainRepr`, including the one-element case. `_from_json` then rebuilt
ordinary failures as `ExceptionChainRepr` instead of the historical
single-exception `ReprExceptionInfo` shape.

Expected behavior: actual chained failures should gain structured chain data;
ordinary single-exception reports should retain the previous round-trip shape
while preserving the same terminal output.

Resolution: V2 emits `chain` only when `len(rep.longrepr.chain) > 1`. Covered
by PO-006.

## F-003: Machine checking and test execution remain intentionally open

Classification: proof/tooling limitation imposed by the task, not a code bug.

Evidence: the task forbids running tests, Python, `kompile`, or `kprove`.

Input: all proof obligations in `fvk/PROOF_OBLIGATIONS.md`.

Observed in this session: obligations were constructed and reviewed by static
reasoning only.

Expected next step outside this constrained session: run the emitted K commands
and relevant pytest tests before using the proof to remove tests or claim a
machine-checked result.

Resolution: no source change. Covered by PO-009 and recorded in
`fvk/PROOF.md`.

## Summary

F-001 is the reported issue and is fixed by the structured chain field. F-002
was found during the FVK audit of V1 and fixed by narrowing chain serialization
to multi-element chains. No additional source defect was found in the audited
serialization path.
