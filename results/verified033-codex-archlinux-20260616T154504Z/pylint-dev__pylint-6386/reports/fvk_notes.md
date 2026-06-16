# FVK Notes

Status: constructed, not machine-checked.

## Decisions

Kept the V1 `-v` preprocessable alias. This is justified by `fvk/FINDINGS.md` F1 and `fvk/PROOF_OBLIGATIONS.md` PO1: the short verbose spelling must reach `_set_verbose_mode` before argparse sees it.

Kept the V1 change from long-only preprocessing to registered single-dash preprocessing. This is justified by F1 and PO2: without inspecting `-v`, the short option remains in the normal args list and can reproduce the reported argparse error. Unknown single-dash arguments remain framed by the non-member append path, as required by PO7.

Kept the V1 `kwargs={"nargs": 0}` verbose descriptor change. This is justified by F2, PO5, and PO6: the issue names the `VERBOSE` help metavar as a defect, and the existing `_CallableArgument` path forwards callback kwargs into `argparse.add_argument`.

Added a V2 separator guard in `_preprocess_options`. This is justified by F3 and PO4: after V1 started inspecting single-dash arguments, `["--", "-v"]` would consume `-v` as verbose even though `--` should end option preprocessing. The guard appends the separator and all following arguments unchanged, then stops early preprocessing.

Rejected a global `_DoNothingAction` constructor change. This remains rejected for the reason captured by the V1 notes and is supported by PO7: `_DoNothingAction` is also used as the placeholder for value-taking preprocessed options such as `--rcfile`, `--output`, and `--init-hook`; the zero-argument requirement is specific to verbose.

## Verification Boundary

The FVK proof is intentionally scoped to the issue's observable behavior: verbose preprocessing, verbose argparse metadata, and the separator frame condition introduced by the V1 audit. It does not claim to verify full Pylint startup, config parsing, plugin loading, linting, reporting, or multiprocessing.

No tests, Python, `kompile`, or `kprove` were run, per task instructions. The proof commands are recorded in `fvk/PROOF.md` for later use in an execution-capable environment.
