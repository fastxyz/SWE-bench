# FVK Notes

## Decision

V1 stands unchanged. No additional source edit is justified by the FVK audit.

## Trace To Findings And Obligations

- Kept the unittest fixture-name change in `repo/src/_pytest/unittest.py`
  because `fvk/FINDINGS.md` F1 identifies the original public-name behavior as
  the reported bug, and `fvk/PROOF_OBLIGATIONS.md` PO1 and PO3 require the
  generated unittest argname to start with `_` and then be hidden by
  non-verbose fixture listing.
- Kept the xunit fixture-name changes in `repo/src/_pytest/python.py` because
  F2 identifies the xunit generated-name family as part of the same issue, and
  PO2 and PO5 require all generated xunit setup fixture names to carry the `_`
  prefix. This covers module, function, class, and method xunit generated
  fixtures.
- Did not rename helper functions, attachment attributes, scopes, or fixture
  bodies because F3 and PO4 frame the required behavior preservation: the public
  issue is about fixture-listing visibility, and the setup/teardown execution
  path should remain unchanged.
- Did not add a compatibility shim for the old generated names because PO6 and
  `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` classify them as generated internal
  autouse fixture argnames, not documented public APIs. The public intent
  specifically requires replacing the visible names with private ones.
- Did not run or modify tests because the task forbids test execution and test
  edits. F4 records the proof as constructed, not machine-checked, and
  `fvk/PROOF.md` keeps all test-removal recommendations conditional on a future
  machine check.

## Artifacts Produced

The requested FVK artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

The FVK method also requires formal and adequacy artifacts, so I added:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-fixture-names.k`
- `fvk/generated-fixture-privacy-spec.k`

## Residual Risk

The proof is constructed by static reasoning only. The benchmark instructions
forbid running K tooling, so `kompile`, `kast`, and `kprove` were not executed.
The source decision is therefore based on public intent, static source
inspection, and the constructed proof obligations rather than machine-checked
FVK output.
