# FVK Notes

## Summary

The FVK audit confirmed the V1 parser and resolver design, then found one
downstream asymmetry: V1 skipped generated entries during figure numbering but
not explicitly during section numbering. V2 fixes that collector path and leaves
the parser/resolver behavior unchanged.

## Decisions

* Kept the V1 parser change in `repo/sphinx/directives/other.py`.
  * Trace: `fvk/FINDINGS.md` F2; `fvk/PROOF_OBLIGATIONS.md` PO-1 and PO-3.
  * Reason: the parser accepts `genindex`, `modindex`, and `search` only after
    normal document lookup fails, appends them to `entries`, and keeps them out
    of `includefiles`.
* Kept the V1 resolver change in `repo/sphinx/environment/adapters/toctree.py`.
  * Trace: F2; PO-2.
  * Reason: generated entries resolve through standard-domain labels, including
    `modindex -> py-modindex`, and explicit toctree titles still override label
    titles.
* Minimally cleaned up `get_toctree_generated_target`.
  * Trace: PO-2/PO-5.
  * Reason: removing the redundant `else` after `return` does not change
    behavior; it keeps the helper simple while preserving the exact generated
    target predicate used by the proof obligations.
* Changed `repo/sphinx/environment/collectors/toctree.py` so
  `assign_section_numbers` explicitly skips generated entries.
  * Trace: F1; PO-4.
  * Reason: generated pages are links, not source doctrees. Figure numbering
    already had this guard in V1; section numbering now follows the same
    invariant and avoids treating a generated label as an assignable source doc.
* Kept the generated special-case set limited to `genindex`, `modindex`, and
  `search`.
  * Trace: `fvk/PUBLIC_EVIDENCE_LEDGER.md` E1/E2; PO-5.
  * Reason: the public issue names exactly those labels. Broadening to arbitrary
    standard-domain labels would change toctree semantics without public intent
    evidence.

## Verification status

The FVK proof artifacts are constructed, not machine-checked. Per the task
constraints, I did not run tests, Python, `kompile`, `kast`, or `kprove`. The
commands to reproduce the machine check later are recorded in `fvk/PROOF.md`.

