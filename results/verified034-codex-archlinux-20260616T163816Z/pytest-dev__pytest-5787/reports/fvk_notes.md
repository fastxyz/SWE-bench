# FVK Notes

## Decisions

The V1 approach of adding structured exception-chain serialization stands. F-001
identifies the original bug: report serialization kept only the top-level
`reprtraceback` and `reprcrash`, which for `ExceptionChainRepr` describe only
the newest exception. PO-004 and PO-005 require multi-exception chains to carry
all chain elements, their order, crash locations, tracebacks, descriptions, and
sections. The V1 helper structure already satisfies that obligation, so those
parts were kept.

The FVK audit found one V1 compatibility problem and I changed the source for
it. F-002 shows that pytest uses `ExceptionChainRepr` even for a normal
single-exception failure, so V1's unconditional `chain` field changed ordinary
round trips from the historical `ReprExceptionInfo` shape to
`ExceptionChainRepr`. PO-006 requires single-exception reports to keep the
previous no-chain serialized shape while preserving terminal output. I changed
`_serialize_exception_longrepr` to emit the `chain` field only when
`len(rep.longrepr.chain) > 1`.

The top-level `reprtraceback`, `reprcrash`, and `sections` fields remain in the
serialized dictionary. This is justified by PO-004 for chained reports and by
PO-006/PO-007 for compatibility with existing report consumers.

I did not change `_pytest._code.code.ExceptionChainRepr`. F-001 localizes the
defect to report serialization, and PO-005 relies on the existing
`ExceptionChainRepr.toterminal` behavior to render the preserved chain in order.

I did not change test files or run tests. F-003 and PO-009 record the task's
no-execution constraint; the proof is constructed, not machine-checked.

## Artifact Map

`fvk/SPEC.md` contains the intent-only spec, evidence ledger, adequacy audit,
and compatibility audit.

`fvk/FINDINGS.md` records the original serialization bug, the V1 compatibility
bug, and the no-execution limitation.

`fvk/PROOF_OBLIGATIONS.md` names the obligations used to audit the fix.

`fvk/PROOF.md` gives the constructed proof and exact K commands that should be
run later in a real execution environment.

`fvk/ITERATION_GUIDANCE.md` explains the V2 code decision and future tests.
