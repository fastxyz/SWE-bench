# Intent Specification

Status: constructed from public evidence only. Candidate/V1 behavior is checked
against these obligations, not used as intent by itself.

## Required behavior

I1. `sphinx-quickstart` must not overwrite an existing Sphinx project.

I2. If the selected root path already contains `conf.py`, the command must stop
with status 1 before generating files.

I3. If the selected root path already contains `source/conf.py`, treat it as an
existing Sphinx project and stop with status 1 before generating files. This is
the separate-source layout already recognized by quickstart and supported by
the documented `--sep` source/build split.

I4. The existing-project path must not ask for a replacement path whose empty
input is then validated as a filesystem path. The reported bad behavior is:
user presses Enter at the "or just Enter to exit" prompt and receives "Please
enter a valid path name."

I5. The public hint resolves the remediation shape: when the selected path
already has a `conf.py`, quickstart should exit with status 1 immediately. This
means the replacement-root retry prompt is not an intent obligation.

I6. Existing successful interactive/quiet paths are frame conditions: V1 should
not change option parsing, normal project generation, quiet-mode validation, or
the public signatures of `ask_user()` and `main()`.

## Out of scope for this audit

The full interactive questionnaire after a valid empty root is not re-proved
here. It is included only as a frame condition because the V1 diff does not
change those prompts.
