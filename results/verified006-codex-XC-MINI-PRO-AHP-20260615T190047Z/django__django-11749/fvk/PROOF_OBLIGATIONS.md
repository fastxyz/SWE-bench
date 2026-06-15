# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Normalize kwarg names before required-option decisions

Statement: every supplied kwarg key that corresponds to a parser option-string
alias is mapped through `opt_mapping` into its action `dest` before deciding
whether required parser validation needs a synthetic token.

Source: `arg_options = {opt_mapping.get(key, key): value ...}` and V1's
`opt.dest in arg_options` checks.

Evidence: E-003, E-004.

Status: discharged by source inspection.

## PO-002: Preserve ordinary required options

Statement: for every parser action where `opt.required` is true and `opt.dest`
is present in `arg_options`, `parse_args` receives an option token produced from
that action.

Source: V1 `required_options = [opt for opt in parser_actions if opt.required
and opt.dest in arg_options]`, followed by `parse_args.extend(get_option_args(opt))`.

Evidence: I-003.

Status: discharged by source inspection and represented in
`call-command-spec.k`.

## PO-003: Include supplied required mutually exclusive group options

Statement: for every required mutually exclusive group, if a group action's
`dest` is present in `arg_options`, `parse_args` receives a token for that
action before parser validation.

Source: `get_mutually_exclusive_required_options()` yields group actions whose
dest is supplied, and the shared `required_options` loop appends their tokens.

Evidence: I-001, I-002, F-001.

Status: discharged by source inspection and represented in
`call-command-spec.k`.

## PO-004: Delegate missing-group and conflict behavior to argparse

Statement: if no group action dest is supplied, V1 appends no synthetic group
token. If multiple group action dests are supplied, V1 appends all corresponding
tokens. In both cases, `parser.parse_args()` remains the validator.

Source: `get_mutually_exclusive_required_options()` filters each action
independently; it neither fabricates absent values nor stops after the first
supplied value.

Evidence: I-004, F-002.

Status: discharged by source inspection.

## PO-005: Preserve final kwarg values

Statement: synthetic parser tokens only satisfy parser validation; the values
passed to `command.execute()` still come from normalized kwargs.

Source: `defaults = dict(defaults._get_kwargs(), **arg_options)`.

Evidence: E-004.

Status: discharged by unchanged source.

## PO-006: Preserve unknown-option rejection

Statement: truly unknown kwargs still raise `TypeError`.

Source: V1 leaves `unknown_options = set(options) - valid_options` unchanged.

Evidence: E-005.

Status: discharged by unchanged source.

## PO-007: Preserve public API compatibility

Statement: the public callable signature and downstream `command.execute()` call
shape are unchanged.

Source: V1 edits only local helper logic inside `call_command()`.

Evidence: I-005 and the public compatibility audit in SPEC.md.

Status: discharged by source inspection.

## PO-008: Respect existing subparser traversal shape

Statement: required mutually exclusive groups in subparsers are discovered with
the same recursive traversal shape already used for parser actions.

Source: V1 mirrors `get_actions()` recursion over `_SubParsersAction.choices`.

Evidence: existing source already recursively handles required subparser
actions; V1 applies the same pattern to required groups.

Status: discharged by source inspection.

## PO-009: No execution-dependent claim

Statement: no proof step relies on tests, hidden evaluator output, Python
execution, or K execution.

Source: task constraints and this artifact set.

Status: discharged; commands are recorded but not run.
