# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F1: CLI subparser errors took the programmatic error branch

Input: a management command invoked as `manage.py cheeses create`, where
`create` is a subparser requiring the positional argument `name`.

Observed before the fix: the child `CommandParser` had no inherited
`called_from_command_line` value, so `CommandParser.error()` raised
`CommandError`. Because parsing occurs before `run_from_argv()` enters its
`CommandError` handler for command execution, the CLI showed a traceback.

Expected: the child parser must behave like the top-level command-line parser:
print usage and a human-facing argparse error for the missing `name` argument.

Classification: code bug.

Status: resolved by `repo/django/core/management/base.py`, where
`CommandParser.add_subparsers()` supplies inherited
`called_from_command_line` as the default for Django child parser construction.

Related proof obligations: PO1, PO3, PO7.

## F2: Programmatic `call_command()` behavior must not become `SystemExit`

Input: a programmatic call such as `call_command("subparser", "foo")` where the
selected child subparser is missing a required argument or option.

Observed before V1: child parser errors raised `CommandError`, matching
Django's programmatic command contract.

Expected: the fix must preserve that behavior; only command-line invocation
should use argparse's `SystemExit` usage path.

Classification: compatibility requirement.

Status: resolved by inheriting the parent's actual mode value. A programmatic
parent has `_called_from_command_line = False`, so the child also defaults to
false and still raises `CommandError`.

Related proof obligations: PO2, PO3.

## F3: V1 over-touched non-Django `parser_class` values

Input: `CommandParser.add_subparsers(parser_class=<non-Django parser class or
factory>)`.

Observed in V1: the method popped and rewrote `parser_class` unconditionally,
including an explicit `None` value, before delegating to argparse.

Expected: the fix should intervene only when argparse would construct a Django
`CommandParser` child. Non-Django parser classes or factories are outside the
Django-specific inheritance requirement and should remain controlled by
argparse.

Classification: compatibility risk.

Status: resolved in V2. `add_subparsers()` now reads `parser_class` with
`kwargs.get()` for classification and mutates `kwargs` only when the value is a
`CommandParser` class or subclass.

Related proof obligations: PO4.

## F4: V1 late-bound the parent mode through the wrapper closure

Input: a subparser action is created from a Django parent parser, and child
parsers are constructed later.

Observed in V1: the wrapper read `self.called_from_command_line` when
`add_parser()` constructed the child parser.

Expected: the issue asks for subparser construction to copy the relevant parser
context. The copied value should be the parent mode at `add_subparsers()` time,
not an accidental future mutation of the parent object.

Classification: robustness improvement.

Status: resolved in V2. The wrapper captures `called_from_command_line` in a
local variable before it is installed as the child parser factory.

Related proof obligations: PO1, PO5.

## F5: `missing_args_message` should not be inherited by default

Input: a command with a command-level `missing_args_message` and a selected
subparser that has its own required argument.

Observed if inherited indiscriminately: after the subcommand is selected, an
empty child argument list could trigger the parent command's generic missing
argument message instead of the subparser-specific error, e.g. missing `name`.

Expected: the parent command-level message applies before a subcommand is
selected. A child parser should get a `missing_args_message` only if its own
`add_parser()` call explicitly supplies one.

Classification: rejected alternative, no code change needed.

Status: V2 intentionally keeps V1's decision not to propagate
`missing_args_message`.

Related proof obligations: PO6.

## F6: Proof is constructed but not machine-checked

Input: the FVK proof obligations and K-style claims in this run.

Observed: commands are recorded but not executed, per task constraints.

Expected: no claim should be presented as machine-verified, and no tests should
be removed.

Classification: proof capability and environment constraint.

Status: documented in `fvk/PROOF.md` and `fvk/PROOF_OBLIGATIONS.md`.

Related proof obligations: PO8.
