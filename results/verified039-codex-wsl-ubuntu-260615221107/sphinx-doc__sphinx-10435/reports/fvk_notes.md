# FVK Notes

## Decision: keep V1 source unchanged

V1 stands because `fvk/FINDINGS.md` F1 identifies the actual bug as TeX-visible
boundary spaces from formatter newlines, and `fvk/PROOF_OBLIGATIONS.md` O1 and
O2 show the V1 patch hides both boundary line endings with `%` comments. O3
shows the highlighted token stream is preserved, so no additional source edit is
needed.

## Decision: do not broaden the source change

The fix remains limited to the highlighted inline `code` role branch. F3 traces
the branch domain to the public reproducer and to `roles.code_role()`, while O0
states the same branch-domain obligation. F4 and O4 show non-highlighted
literals, keyboard/title literals, and literal blocks are framed, so broadening
the patch would add risk without serving the issue intent.

## Decision: do not modify tests

F2 marks the existing inline assertion in `test_latex_code_role` as a SUSPECT
public-test obligation because it records the raw-newline shape described by the
issue as buggy. The benchmark forbids test edits, so the test file was left
unchanged. Future maintainers should update that assertion to expect the
commented boundary form or an equivalent no-visible-boundary-space form.

## Decision: no compatibility repair

O5 records that the patch changes only local LaTeX string assembly inside
`visit_literal()`. F4 confirms there is no changed public symbol, method
signature, node shape, or producer/consumer protocol. Therefore no compatibility
follow-up edit is needed.

## Decision: constructed proof only

F5 and O6 record the environment limitation: tests, Python, and K tooling must
not be run. I emitted `fvk/mini-latex-inline.k`,
`fvk/latex-inline-code-spec.k`, and the exact commands in `fvk/PROOF.md`, but
left the result labeled constructed, not machine-checked.
