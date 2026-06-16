# Baseline Notes

## Root cause

`--verbose` is handled before normal configuration parsing by
`pylint.config.utils._preprocess_options`, which removes the option from the
argument list and sets `Run.verbose`. That preprocessing only considered
arguments starting with `--`, so the short form `-v` was left for argparse.

The registered argparse action for `verbose` is `_DoNothingAction`, a placeholder
used after preprocessing. Without per-option `nargs` metadata, argparse treated
that custom action as taking one value, which made `-v` fail with "expected one
argument" and made help output display a `VERBOSE` metavar.

## Changed files

`repo/pylint/config/utils.py`

Added `-v` as a preprocessable alias for `--verbose` and allowed the
preprocessor to inspect single-dash options. This makes `-v` set
`Run.verbose` and removes it before the later argparse pass, matching the long
option behavior.

`repo/pylint/lint/base_options.py`

Changed the `verbose` option's forwarded argparse kwargs to `{"nargs": 0}`.
This keeps the placeholder action for `verbose` as a flag when argparse builds
help or encounters the option after preprocessing, so the help text no longer
suggests a required value.

## Assumptions and alternatives considered

I assumed `-v` should be exactly equivalent to `--verbose`: it should not accept
a value, and it should enable verbose mode before config-file discovery and
parsing.

I considered changing `_DoNothingAction` globally to always use `nargs=0`, but
rejected that because the same placeholder action is also used for preprocessed
options that take values, such as `--rcfile`, `--output`, and `--init-hook`.
A global change would alter those options' fallback argparse behavior and config
parsing surface. Applying `nargs=0` only to `verbose` is narrower.

I also considered adding a generic short-option alias expansion system for all
preprocessed options. The reported bug only involves `verbose`, and no other
preprocessed option in the current run options has a short alias that needs this
path, so a direct `-v` alias is the smallest targeted change.
