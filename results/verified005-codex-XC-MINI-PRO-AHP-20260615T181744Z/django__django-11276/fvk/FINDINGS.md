# Findings

Status: FVK audit of V1. Findings are based on public evidence and constructed
proof obligations; no tests, Python code, or K tooling were run.

## F1 - Resolved: duplicated escaping table replaced

- Classification: code bug / implementation duplication, resolved by V1.
- Evidence: E1 and E2 say `django.utils.html.escape()` should use stdlib
  `html.escape()` instead of a partial duplicate.
- Pre-V1 input: `"'&<>"`
- Pre-V1 observed mechanism: local `_html_escapes` table and `str.translate()`,
  including apostrophe output `&#39;`.
- Expected: delegation to stdlib `html.escape(str(text), quote=True)`, including
  apostrophe output `&#x27;`.
- V1 disposition: fixed by PO1, PO2, and PO5.

## F2 - SUSPECT legacy exact-output tests

- Classification: stale public-test evidence relative to issue intent.
- Evidence: visible tests under `repo/tests/` assert the legacy apostrophe
  literal `&#39;`.
- Conflict: E5 explicitly identifies stdlib's `&#x27;` output as the intended
  consequence of the change, while noting it as backwards-incompatible literal
  text.
- Input: `"'"`.
- Legacy expected by visible tests: `&#39;`.
- Expected by issue intent and stdlib delegation: `&#x27;`.
- V1 disposition: do not preserve `&#39;` in `escape()` merely for old tests.
  Tests were not modified because the benchmark forbids test edits.

## F3 - Resolved: `urlize()` helper needed `&#x27;` compatibility

- Classification: compatibility gap found by the FVK frame audit, resolved by
  V1.
- Evidence: E10 says HTML-escaped URL input is unescaped before
  `smart_urlquote()`. After F1, escaped apostrophes may be spelled `&#x27;`.
- Input: `http://example.test/?q=&#x27;`
- Without the V1 helper adjustment: the local helper would leave `&#x27;` intact
  while it already converted `&#39;`.
- Expected: `http://example.test/?q='` should be fed to URL quoting, matching
  the old behavior for the old apostrophe spelling.
- V1 disposition: fixed by PO8; both `&#39;` and `&#x27;` are accepted.

## F4 - Residual: proof is constructed, not machine-checked

- Classification: proof capability / execution-environment gap, not a source
  bug.
- Evidence: benchmark instructions prohibit running Python, tests, `kompile`,
  or `kprove`; FVK honesty gate requires labeling the proof accordingly.
- Impact: no test removal is justified in this benchmark run.
- Recommendation: outside this benchmark, run the exact commands listed in
  `PROOF.md` and then the relevant Django tests.

## F5 - Residual: lazy wrapper modeled as a frame condition

- Classification: proof abstraction caveat, not a V1 code bug.
- Evidence: `@keep_lazy(str, SafeString)` remains unchanged around `escape()`.
- Scope: the K proof models the eager body the decorator invokes. It does not
  re-verify Django's lazy proxy machinery.
- V1 disposition: no source change. A source edit to the decorator path would
  be unrelated to this issue and unsupported by the findings.

## Proof-Derived Summary

The constructed proof obligations support keeping V1 source unchanged. The only
legacy conflict is the exact apostrophe spelling, and public issue intent
resolves that conflict in favor of stdlib `&#x27;`.
