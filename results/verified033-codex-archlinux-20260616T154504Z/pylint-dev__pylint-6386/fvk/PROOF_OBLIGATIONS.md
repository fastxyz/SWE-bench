# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Short verbose is registered as preprocessable

Claim: `PREPROCESSABLE_OPTIONS["-v"] == (False, _set_verbose_mode)`.

Why: discharges F1 by giving `-v` the same no-value callback path as `--verbose`.

Code evidence: `repo/pylint/config/utils.py`.

## PO2: The preprocessor can inspect registered single-dash aliases

Claim: `_preprocess_options` does not skip all single-dash arguments before lookup; it parses the option spelling and checks membership in `PREPROCESSABLE_OPTIONS`.

Why: discharges F1 for `-v`; preserving unknown single-dash arguments follows because non-members are appended unchanged.

Code evidence: `repo/pylint/config/utils.py`.

## PO3: Short verbose remains no-value

Claim: for `-v`, `takearg` is `False`; if the token has an inline value, `_preprocess_options` raises `ArgumentPreprocessingError` rather than consuming the value.

Why: discharges I2 and prevents replacing "expected one argument" with value-taking behavior.

Code evidence: `PREPROCESSABLE_OPTIONS["-v"]` and the existing `elif not takearg and value is not None` branch.

## PO4: Separator frame

Claim: if the current argument is `"--"`, `_preprocess_options` appends the separator and the rest of the input to `processed_args` and stops; no callbacks are run for following tokens.

Why: discharges F3 and preserves normal command-line separator behavior after broadening preprocessing to single-dash aliases.

Code evidence: `repo/pylint/config/utils.py`.

## PO5: Verbose option has zero-argument argparse metadata

Claim: the `verbose` option descriptor in `_make_run_options` contains `kwargs: {"nargs": 0}`.

Why: discharges F2 by making argparse parse and render verbose as a flag.

Code evidence: `repo/pylint/lint/base_options.py`.

## PO6: Callback kwargs reach argparse

Claim: `_convert_option_to_argument` stores callback `kwargs` in `_CallableArgument`, and `_ArgumentsManager._add_parser_option` passes `**argument.kwargs` into `section_group.add_argument`.

Why: connects PO5 to the actual parser/help observable.

Code evidence: `repo/pylint/config/utils.py`, `repo/pylint/config/argument.py`, and `repo/pylint/config/arguments_manager.py`.

## PO7: Frame for unrelated arguments and options

Claim: unknown or non-preprocessable arguments before `--` are appended unchanged; existing long preprocessable options keep their existing mapping and value-taking behavior.

Why: ensures the fix is targeted to verbose and does not refactor unrelated startup behavior.

Code evidence: unchanged `PREPROCESSABLE_OPTIONS` entries and the existing non-member append branch.

## PO8: Honesty gate

Claim: the proof artifacts are constructed only; no `kompile`, `kprove`, tests, Python execution, or K tooling was run.

Why: required by the task and FVK MVP honesty gate.
