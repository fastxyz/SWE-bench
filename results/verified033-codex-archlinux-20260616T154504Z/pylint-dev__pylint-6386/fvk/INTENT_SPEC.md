# Intent Spec

Status: constructed, not machine-checked.

Scope: the V1/V2 fix for `pylint-dev__pylint-6386`, specifically the public behavior of `pylint` startup argument preprocessing for verbose mode and the argparse metadata that renders/parses the `verbose` option.

## Required Behaviors

I1. `-v` is the short spelling of `--verbose`.

Evidence: `benchmark/PROBLEM.md` says "The short option of the `verbose` option expects an argument" and the expected behavior is "Similar behaviour to the long option."

Obligation: for command-line arguments before any option separator, `-v` must enable `Run.verbose` exactly as `--verbose` does.

I2. Verbose mode is a flag, not a value-taking option.

Evidence: `benchmark/PROBLEM.md` says "`pylint mytest.py --verbose`" works and "doesn't expect an argument"; it reports "`pylint mytest.py -v`" failing with "expected one argument."

Obligation: `-v` and `--verbose` must not consume a following value. Supplying an inline value such as `-v=VALUE` or `--verbose=VALUE` is outside the flag form and should be rejected consistently with the existing long-option behavior.

I3. Help must not advertise a verbose argument value.

Evidence: `benchmark/PROBLEM.md` says "the help message for the `verbose` option suggests a value `VERBOSE` should be provided."

Obligation: the argparse action metadata for the `verbose` option must be zero-argument metadata, so help renders it as a flag rather than as `--verbose VERBOSE` / `-v VERBOSE`.

I4. Non-verbose command-line arguments are frame state for this issue.

Evidence: `repo/doc/technical_reference/startup.rst` says `Run` does basic command-line preprocessing to find init hook, config file, and plugins before normal linter initialization. The issue does not request changes to those options.

Obligation: the fix must preserve existing preprocessing behavior for unrelated preprocessed long options and pass unknown/non-preprocessed arguments through unchanged.

I5. The `--` argument separator stops option preprocessing.

Evidence: `pylint.__init__.run_pylint` documents `argv` as "strings normally supplied as arguments on the command line"; preserving `--` as an end-of-options separator is a standard command-line default-domain convention and is consistent with the later argparse parser.

Obligation: once `_preprocess_options` sees `--`, the separator and all following arguments must pass through untouched; in particular, `-v` after `--` must not enable verbose mode.

## Out Of Scope

This FVK pass does not prove full Pylint linting behavior, plugin loading, config-file parsing, multiprocessing, or reporter behavior. Those are outside the issue's observable defect and outside the V1/V2 code changes.
