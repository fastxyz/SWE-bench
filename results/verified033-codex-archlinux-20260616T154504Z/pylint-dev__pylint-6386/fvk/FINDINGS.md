# FVK Findings

Status: constructed, not machine-checked.

## F1: Short verbose reached argparse instead of preprocessing

Input: `["mytest.py", "-v"]`

Observed before the repair: `_preprocess_options` only inspected arguments beginning with `--`, so `-v` remained in the returned args. The later argparse action for `_DoNothingAction` treated it as value-taking and produced "argument --verbose/-v: expected one argument."

Expected from intent: `-v` behaves like `--verbose`: it sets `Run.verbose = True`, takes no value, and is removed before normal config parsing.

Resolution: V1/V2 add `"-v": (False, _set_verbose_mode)` to `PREPROCESSABLE_OPTIONS` and inspect single-dash arguments for registered preprocessable options.

Related proof obligations: PO1, PO2, PO3.

## F2: Verbose argparse metadata advertised an argument

Input/observable: generated help for `--verbose` / `-v`.

Observed before the repair: the callback action was registered without `nargs=0`, so argparse treated the custom action as taking one value and help exposed a `VERBOSE` metavar.

Expected from intent: verbose is a no-argument flag, so help and parsing metadata must not imply a value.

Resolution: V1/V2 set the `verbose` option descriptor kwargs to `{"nargs": 0}`. Existing argument-conversion code forwards callback kwargs to `argparse.add_argument`.

Related proof obligations: PO5, PO6.

## F3: V1 consumed short verbose after the `--` separator

Input: `["--", "-v"]`

Observed in V1 by static symbolic execution: `_preprocess_options` appended `"--"` as an unknown argument, then continued scanning and consumed `"-v"` as verbose. Result: output `["--"]`, `Run.verbose = True`.

Expected from default command-line convention: `--` ends option processing. The separator and following `-v` should pass through untouched, with `Run.verbose` unchanged by that following token.

Resolution: V2 adds an explicit separator guard that extends `processed_args` with `args[i:]` and breaks before further preprocessing.

Related proof obligations: PO4, PO7.

## Residual Findings

No unresolved code bug remains inside the scoped verbose CLI contract. The proof is constructed from a mini-K model and was not machine-checked; running the recorded `kompile`/`kprove` commands is still required before treating the formal claims as machine-verified.
