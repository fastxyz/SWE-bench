# FVK Notes

## Decisions

### Added dependency recording for class-alias source comments

FVK finding: `fvk/FINDINGS.md` F1.

Proof obligations: `fvk/PROOF_OBLIGATIONS.md` PO4 and PO5.

Decision: update `ClassDocumenter.get_docstring_comment()` so that when it finds
a source docstring-comment in the aliasing module/class scope, it also records
`analyzer.srcname` in `self.directive.record_dependencies`.

Reasoning: V1 introduced a new path where `ClassDocumenter` reads source
comments from `self.modname` rather than from the aliased class object's real
module. Existing autodoc analyzer use records source files as dependencies, so
the new source read should preserve that frame condition.

### Kept V1 fallback suppression for documented data and attribute aliases

FVK finding: `fvk/FINDINGS.md` F2.

Proof obligations: `fvk/PROOF_OBLIGATIONS.md` PO1, PO2, and PO3.

Decision: keep V1's `has_docstring_comment()` hook and the guards in
`GenericAliasMixin`, `NewTypeMixin`, and `TypeVarMixin`.

Reasoning: the public issue asks for documented type aliases to show source
docstrings instead of generated `alias of ...` text. The proof obligations
separate documented and undocumented aliases, so fallback remains available when
there is no source docstring-comment.

### Kept V1 class-alias content behavior

FVK finding: `fvk/FINDINGS.md` F2.

Proof obligations: `fvk/PROOF_OBLIGATIONS.md` PO4.

Decision: keep V1's `ClassDocumenter.doc_as_attr` behavior of returning source
comments from the aliasing scope when present and suppressing generated fallback
for that documented alias.

Reasoning: Python 3.6-style `typing.Dict[...]` and `typing.Callable[...]`
aliases can route through class-alias handling, which was the inconsistent path
identified in `reports/baseline_notes.md`. The FVK model requires this path to
match the same documented-alias contract as data aliases.

### Did not change manual directive body behavior

FVK finding: `fvk/FINDINGS.md` F3.

Proof obligation: `fvk/PROOF_OBLIGATIONS.md` PO7.

Decision: no source change for undocumented aliases with manual directive body
content.

Reasoning: the public issue is specifically about source next-line docstrings
for type aliases. Manual directive content is not specified by the issue, so it
is recorded as residual scope rather than used to broaden the patch.

### Did not run tests or formal tools

FVK finding: `fvk/FINDINGS.md` F4.

Proof obligation: `fvk/PROOF_OBLIGATIONS.md` PO8.

Decision: no tests, Python commands, `kompile`, `kast`, or `kprove` were run.

Reasoning: the task explicitly forbids execution. The FVK artifacts include the
constructed proof, mini semantics, claims, and commands to run later in an
environment where execution is allowed.
