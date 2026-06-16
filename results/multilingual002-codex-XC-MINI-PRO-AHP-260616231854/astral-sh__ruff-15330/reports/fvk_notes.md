# FVK Notes

The FVK audit confirmed V1 without further source edits.

## Decisions

- Kept `repo/crates/ruff_linter/src/rules/eradicate/rules/commented_out_code.rs` unchanged after
  V1. `fvk/FINDINGS.md` F1 traces the reported false positive to delimiter selection, and
  `fvk/PROOF_OBLIGATIONS.md` PO3 shows V1 now selects the last `# ///` delimiter in the valid
  embedded-content prefix. PO5 then shows the selected metadata comments cannot reach
  `comment_contains_code`.
- Did not broaden suppression to comments after the selected delimiter. `fvk/FINDINGS.md` F3 and
  PO4/PO7 justify this as a frame condition: the public issue requires avoiding false positives
  inside inline script metadata, while ordinary comments outside the selected skip range remain part
  of the normal ERA001 rule behavior.
- Preserved unclosed-block behavior. `fvk/FINDINGS.md` F2 and PO6 show V1 still returns `false`
  when no delimiter exists, so malformed script-tag-like comments do not suppress diagnostics.
- Did not run tests, Ruff, Python, or K tooling. `fvk/FINDINGS.md` F4 and PO8 record the task's
  no-execution constraint; `fvk/PROOF.md` lists the commands to run later but labels the proof
  constructed, not machine-checked.

## Artifacts

- `fvk/SPEC.md` records the intent ledger, formal model, adequacy audit, and compatibility audit.
- `fvk/FINDINGS.md` records the closed findings and residual no-execution caveat.
- `fvk/PROOF_OBLIGATIONS.md` lists PO1 through PO8.
- `fvk/PROOF.md` gives the constructed proof and deferred K commands.
- `fvk/ITERATION_GUIDANCE.md` states that V1 stands and recommends a future regression test.
- `fvk/mini-era001-script-scan.k` and `fvk/era001-script-scan-spec.k` provide the constructed K
  core referenced by the proof.
