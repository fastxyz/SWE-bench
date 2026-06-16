# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 change in
`repo/sphinx/cmd/quickstart.py`, specifically the existing-project branch in
`ask_user()` and the way `main()` reports the resulting exit status. The rest of
the interactive questionnaire is treated as a frame condition because V1 does
not change it.

Supporting formal artifacts:

- `fvk/mini-python-quickstart.k`
- `fvk/quickstart-spec.k`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

## Public Intent Ledger Summary

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The decisive entries are:

- E1/E3: the bug is triggered by running quickstart in a directory that already
  has `conf.py`; expected behavior is termination instead of another validation
  error.
- E4: the public hint says an already-selected root containing `conf.py` should
  exit with status 1 immediately.
- E5: quickstart must not overwrite existing Sphinx projects.
- E6: the existing code recognizes both `conf.py` and `source/conf.py` as
  existing-project indicators.

The replacement-root prompt is marked SUSPECT legacy evidence because it is the
UI element through which the bug manifests. It is not preserved as an intent
obligation.

## Contract

For the audited interactive path:

1. If `<root>/conf.py` exists, quickstart emits the existing-project warning,
   exits with status 1, does not prompt for a replacement root, and does not
   generate files.
2. If `<root>/source/conf.py` exists, quickstart has the same status-1,
   no-prompt, no-generation behavior.
3. If neither file exists, the existing-project guard is not taken; this patch
   leaves the later questionnaire/generation flow unchanged.
4. `main()` reports the status-1 exit as an integer return code when called as a
   function, and `__main__` still turns that return code into the process status.

## Preconditions

- The selected root path has already been chosen by argparse or the initial root
  prompt.
- Filesystem predicates for `<root>/conf.py` and `<root>/source/conf.py` are
  stable during this check.
- This is a partial-correctness spec over the audited branch; termination of the
  rest of the interactive wizard is outside the proof.

## Formal Claims

`QS-EXISTING-ROOT`: from `mainInteractive` with `rootConf = true`, all paths end
with `status = 1`, `warning = true`, `replacementPrompt = false`, and
`generated = false`.

`QS-EXISTING-SOURCE`: from `mainInteractive` with `rootConf = false` and
`sourceConf = true`, all paths end with the same status-1/no-prompt/no-generation
postcondition.

`QS-NO-CONF-FRAME`: from `mainInteractive` with both conf flags false, the
reduced model reaches generation without the existing-project warning. This is a
frame claim for the patch boundary, not a proof of the entire questionnaire.
