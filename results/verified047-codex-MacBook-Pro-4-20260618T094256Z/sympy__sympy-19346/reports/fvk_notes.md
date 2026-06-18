# FVK Notes

## Decision

V1 stands unchanged. I did not edit any source files after the FVK audit because the artifacts under `fvk/` did not produce a concrete counterexample or unmet proof obligation that V1 fails.

## Trace to FVK artifacts

- `fvk/FINDINGS.md` F1 confirms that V1 addresses the reported failures for `srepr({x, y})` and `srepr({x: y})` by recursively printing set members and dict keys/values.
- `fvk/FINDINGS.md` F2 confirms that V1 preserves the issue's named regression frame for list and tuple output because `_print_list` and `_print_tuple` were not changed.
- `fvk/FINDINGS.md` F3 audits the extra SymPy `Dict` handling and concludes it preserves the eval-friendly wrapper form rather than introducing a regression.
- `fvk/FINDINGS.md` F4 records that exact `default_sort_key` behavior is abstracted in the mini semantics. This is a proof capability boundary, not a demonstrated code defect, because the public issue's required behavior is recursive content printing.
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` found no public callsite, subclass, or override that requires a code change beyond V1.
- `fvk/SPEC_AUDIT.md` marks the formal obligations as matching the public intent, with only the ordering note described above.

## Why no V2 source edit was made

The revision discipline says source edits are justified only by a specific FVK finding that V1 demonstrably fails. The audit found none. The remaining caveats are that the proof is constructed, not machine-checked, and that the K model abstracts full Python and `default_sort_key`; neither caveat identifies a source-level counterexample. Applying a speculative edit would add regression surface without a documented obligation forcing it.

## Commands not run

Per the task constraints, I did not run Python, tests, `kompile`, `kast`, or `kprove`. The intended K commands are recorded in `fvk/PROOF.md`.
