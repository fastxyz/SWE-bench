# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not surface a remaining source-code
defect in the tuple-default fix.

## Trace To Findings And Obligations

`fvk/FINDINGS.md` F1 identifies the original defect: tuple defaults were
converted with the normal AST unparser, which strips parentheses from non-empty
tuple expressions. `fvk/PROOF_OBLIGATIONS.md` O1 and O5 are discharged by the V1
code: `unparse_default()` parenthesizes tuple defaults, and
`signature_from_ast()` uses it for all default-bearing parameter kinds.

`fvk/FINDINGS.md` F2 records the main regression risk: changing tuple unparsing
globally would break annotation/subscript rendering such as `Tuple[int, int]`.
`fvk/PROOF_OBLIGATIONS.md` O3, O4, and O5 are discharged by keeping `unparse()`
unchanged, adding a separate default-value rendering path, preserving the
top-level subscript-slice comma list, and continuing to use normal `ast_unparse`
for annotations and return annotations.

`fvk/FINDINGS.md` F3 checks coverage across parameter kinds. O5 is discharged
because V1 routes positional-only, positional-or-keyword, and keyword-only
defaults through `ast_unparse_default()`.

`fvk/FINDINGS.md` F4 is an honesty caveat, not a code bug. O7 records the
commands that would be used for K machine checking and states that they were not
run because the task forbids tests, Python, and K tooling.

## Changes Made During FVK Phase

No source files under `repo/` were changed during this FVK phase.

Added required FVK artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Added constructed K side artifacts for the formal core:

- `fvk/mini-signature-default.k`
- `fvk/signature-default-spec.k`

## Assumptions

The FVK spec is intentionally scoped to the public issue: preserving tuple
default syntax in Sphinx's Python signature parsing/rendering path. It does not
claim to replace Sphinx's existing cut-down AST unparser with a full-fidelity
Python source unparser.

The proof is constructed from source inspection only. No tests, Python code, or
K tooling were run.
