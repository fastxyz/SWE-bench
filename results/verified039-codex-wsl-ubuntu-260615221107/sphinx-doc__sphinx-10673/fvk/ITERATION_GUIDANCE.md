# Iteration Guidance

Status: constructed, not machine-checked.

## Code decisions for V2

1. Keep the V1 parser generated-entry path.
   * Justification: `FINDINGS.md` F2 and `PROOF_OBLIGATIONS.md` PO-1/PO-3.
   * Reason: it accepts only the three issue labels after normal source lookup
     fails, keeps them out of `includefiles`, and preserves unknown-document
     warnings.
2. Keep the V1 resolver generated-link path.
   * Justification: F2 and PO-2.
   * Reason: it reuses standard-domain label data and maps `modindex` to
     `py-modindex`.
3. Revise the V1 collector handling.
   * Justification: F1 and PO-4.
   * Change: add the generated-target skip to `assign_section_numbers`, matching
     the V1 figure-number skip.
4. Keep the special-case set limited to `genindex`, `modindex`, and `search`.
   * Justification: E1/E2 and PO-5.
   * Reason: supporting arbitrary labels in toctrees would broaden toctree
     semantics beyond the issue and beyond current public intent evidence.

## Recommended tests for a future executable environment

Do not edit tests in this task. Future test coverage should include:

* HTML build with a toctree containing `genindex`, `modindex`, and `search` and
  no source documents by those names; expected no nonexisting-document warnings.
* Rendered toctree links include `genindex`, `py-modindex`, and `search`.
* The generated entries are absent from `includefiles` / relation data.
* Numbered toctree plus `numfig` does not attempt to number or load doctrees for
  generated entries.
* A missing non-generated entry still emits the existing warning.
* A real source document still takes precedence when normal source lookup
  succeeds.

## Next proof iteration

Run the emitted K commands in `PROOF.md` when a K environment is available. If
the abstract proof is accepted and more assurance is needed, the next escalation
is a fuller mini-Python/docutils semantics for the exact Python control flow in
`parse_content`, `resolve`, and the numbering collectors.

