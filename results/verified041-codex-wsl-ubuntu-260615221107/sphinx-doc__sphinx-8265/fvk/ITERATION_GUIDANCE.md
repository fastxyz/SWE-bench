# FVK Iteration Guidance

Status: constructed from public intent and source inspection; not machine-checked.

## Decision

V1 stands unchanged.

Reason:

- `fvk/FINDINGS.md` F1 is closed by proof obligations O1 and O5.
- `fvk/FINDINGS.md` F2 is closed by proof obligations O3, O4, and O5.
- `fvk/FINDINGS.md` F3 is closed by proof obligation O5.
- `fvk/FINDINGS.md` F4 is an honesty caveat, not a code defect.

No FVK finding identifies a source-code defect that remains after V1.

## Recommended Next Actions

1. In an execution-capable environment, run the commands recorded in
   `fvk/PROOF.md` if machine-checking the constructed K artifacts is desired.
2. Add focused tests for tuple defaults in `signature_from_str()` and the Python
   domain rendering path. Do not remove tests based on this constructed proof.
3. Keep the fix scoped to default rendering. Do not change global tuple unparse
   behavior unless a separate public intent source requires it.
4. If future issues ask for full-fidelity default-expression unparsing beyond
   Sphinx's existing supported AST subset, treat that as a separate design task.

## Rejected Follow-Up Edits

Global `visit_Tuple()` parenthesizing:

- Rejected by F2 and O3/O4 because it risks changing annotation rendering.

HTML-writer changes:

- Rejected by F1 and O5 because the wrong text is introduced before writer
  translation, when the signature default is converted to a string.

Pseudo-parser changes:

- Rejected because `_pseudo_parse_arglist()` explicitly splits on commas and is
  the wrong layer for preserving comma-bearing default expressions.

Broader AST-unparser rewrite:

- Rejected as outside the public issue. The intent-derived obligation is tuple
  defaults in the Python signature path, not a full replacement for Sphinx's
  cut-down AST unparser.
