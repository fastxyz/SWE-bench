# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Public Surface

`repo/pylint/config/utils.py`

- `PREPROCESSABLE_OPTIONS` gains a `-v` alias for the existing verbose callback.
- `_preprocess_options` now inspects single-dash arguments for preprocessable aliases and stops preprocessing at `--`.
- Signature is unchanged: `_preprocess_options(run: Run, args: Sequence[str]) -> list[str]`.

`repo/pylint/lint/base_options.py`

- The `verbose` option descriptor keeps the same public long and short flags but forwards `kwargs={"nargs": 0}` for its callback action.
- No function signature or return shape changes.

## Callsite And Override Audit

| Symbol | Public callers / consumers inspected | Compatibility result |
| --- | --- | --- |
| `_preprocess_options` | `repo/pylint/lint/run.py` calls it with `self` and CLI args, expecting a list of remaining args. | Compatible: return type and error path are unchanged; `-v` is now removed like `--verbose`. |
| `PREPROCESSABLE_OPTIONS` | Used only by `_preprocess_options` in source search. | Compatible: adding `-v` is additive and shares the existing `_set_verbose_mode` callback. |
| `verbose` option descriptor | `_convert_option_to_argument` creates `_CallableArgument`; `_ArgumentsManager._add_parser_option` forwards `argument.kwargs` to `add_argument`. | Compatible: `kwargs` was already part of the callback option protocol; no API signature change. |

No public subclass override, virtual dispatch signature, storage format, or return shape is changed.
