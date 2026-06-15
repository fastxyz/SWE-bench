# FVK Notes

## Decisions

D-001: Keep the V1 regex change unchanged. This follows from F-001 and F-002: the legacy `$` anchor accepted a final LF, while V1's `\A...\Z` rejects it and satisfies the accepted-language obligations in PO-001 through PO-003.

D-002: Preserve the existing ASCII and Unicode flag split. This follows from PO-004 and PO-005, which trace the distinction to the public docs, implementation flags, and public examples. No source edit beyond V1 was needed because V1 changed only the anchors and left `flags = re.ASCII` and `flags = 0` intact.

D-003: Do not change `RegexValidator`. This follows from F-003 and PO-006: the public issue scopes the repair to the two auth username validators, while `RegexValidator` is a shared base used by unrelated validators.

D-004: Do not edit tests. This follows from the benchmark rule forbidding test-file modifications and PF-001/PO-007, which state that the constructed proof is not machine-checked and cannot justify deleting tests. `fvk/ITERATION_GUIDANCE.md` records test additions that would be appropriate outside this benchmark.

D-005: Treat the V1 source as V2. PF-002 says no proof obstacle or adequacy failure required another code change. The compatibility audit found no public callsite or migration shape requiring updates.

## Artifacts Produced

The FVK artifact set is under `fvk/`: `SPEC.md`, `FINDINGS.md`, `PROOF_OBLIGATIONS.md`, `PROOF.md`, `ITERATION_GUIDANCE.md`, the adequacy files, and the constructed `.k` files. The recorded K commands were written into the artifacts but not executed.
