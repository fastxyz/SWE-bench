# FVK Spec

Status: constructed, not machine-checked.

## Scope

This specification covers the V2 repair for the verbose CLI issue:

- `repo/pylint/config/utils.py`: `_preprocess_options`, `PREPROCESSABLE_OPTIONS`, and `_set_verbose_mode` as they affect `--verbose`, `-v`, unknown arguments, and `--`.
- `repo/pylint/lint/base_options.py`: the `verbose` option descriptor's forwarded argparse kwargs.
- Existing forwarding behavior in `repo/pylint/config/arguments_manager.py` is treated as implementation evidence: `_CallableArgument.kwargs` are passed into `argparse.add_argument`.

## Intent Ledger

| Intent | Evidence | Obligation |
| --- | --- | --- |
| Verbose short option parity | Problem statement says expected behavior for `pylint mytest.py -v` is "Similar behaviour to the long option." | `-v` before `--` sets `Run.verbose = True` and is removed from the normal args list. |
| Verbose is no-argument | Problem statement says `--verbose` "doesn't expect an argument." | `-v` and `--verbose` are no-value flags; inline values are rejected by preprocessing. |
| Help must not show `VERBOSE` | Problem statement says help suggests value `VERBOSE` should be provided. | The verbose argparse action must have `nargs = 0`. |
| Preserve unrelated args | Startup docs limit preprocessing to early command-line option discovery. | Non-preprocessed arguments remain in order in the returned argument list. |
| Respect option separator | `argv` is normal command-line input; `--` separator is a default-domain command-line convention. | After `--`, no more early preprocessing callbacks run. |

## Formal Contract

Let `preprocess(args, verbose0=false, out0=[])` denote the relevant behavior of `_preprocess_options`.

1. For any `REST`, `preprocess(["-v"] + REST)` performs one verbose callback with `value=None`, sets `verbose=True`, omits `"-v"` from `out`, and continues preprocessing `REST`.
2. For any ordinary non-option argument `A`, `preprocess([A, "-v"])` preserves `A` in `out` and sets `verbose=True`.
3. `preprocess(["-v=VALUE"] + REST)` raises the same no-value preprocessing error shape used for no-argument preprocessable options.
4. `preprocess(["--"] + REST)` returns `["--"] + REST` appended to `out` and leaves `verbose` unchanged by anything in `REST`.
5. The `verbose` option descriptor contributes flags `["--verbose", "-v"]`, action `_DoNothingAction`, and `kwargs["nargs"] == 0`; because `_CallableArgument.kwargs` are forwarded to `argparse.add_argument`, argparse treats verbose as a flag and does not render a `VERBOSE` metavar.

## Frame Conditions

- Existing entries for `--init-hook`, `--rcfile`, `--output`, `--load-plugins`, `--verbose`, and `--enable-all-extensions` remain present.
- Non-preprocessable arguments before `--` remain in their original relative order.
- Value-taking behavior for unrelated preprocessed long options is not changed by the verbose repair.

## Formal Artifacts

- `fvk/mini-cli.k` defines the minimal CLI preprocessing semantics needed for this issue.
- `fvk/cli-verbose-spec.k` contains K reachability claims for short verbose preprocessing, value rejection, separator framing, and verbose `nargs`.
- `fvk/FORMAL_SPEC_ENGLISH.md` paraphrases those claims.
- `fvk/SPEC_AUDIT.md` checks the formal English against this intent spec.
