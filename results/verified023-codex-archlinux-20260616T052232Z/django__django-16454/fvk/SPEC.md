# FVK Specification for django__django-16454

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The audited unit is `django.core.management.base.CommandParser` and its
interaction with Django management command parsing:

- `CommandParser.add_subparsers()`
- `CommandParser.error()`
- `BaseCommand.create_parser()`
- `BaseCommand.run_from_argv()`
- `django.core.management.call_command()`

The observable under verification is error handling for parsers created by
`CommandParser.add_subparsers().add_parser()`.

## Intent Spec

I1. A management command invoked from the command line must report subparser
argument errors as argparse usage errors, not as Python tracebacks.

I2. The behavior must hold for required positional arguments, required options,
invalid options, and nested subparsers, because each uses the same child parser
`error()` path.

I3. Programmatic command invocation must keep Django's existing behavior:
argument parser failures raise `CommandError` instead of `SystemExit`.

I4. The change must be frame-preserving for argparse's public customization
surface. A caller-supplied non-Django `parser_class` must remain controlled by
argparse, and child-parser keyword arguments explicitly passed to `add_parser()`
must take precedence over inherited defaults.

I5. The command-level `missing_args_message` is not automatically a subparser
message. It describes the case where the command itself has no positional
arguments; after a subcommand has been selected, normal subparser-specific
argparse errors should apply unless the subparser is explicitly given its own
`missing_args_message`.

## Public Evidence Ledger

E1. Source: `benchmark/PROBLEM.md`.
Quote: "Management command subparsers don't retain error formatting."
Obligation: subparsers must retain the error formatting context of the Django
management command parser. Status: encoded by I1 and PO1.

E2. Source: `benchmark/PROBLEM.md`.
Quote: "Missing arguments to subparsers thus end as stack traces on the CLI,
rather than human-facing usage messages."
Obligation: a CLI child parser error must use argparse's usage/error path
instead of raising uncaught `CommandError`. Status: encoded by I1, PO1, and PO3.

E3. Source: `benchmark/PROBLEM.md`.
Quote: "We can correct this by ensuring that the subparser action returned by
add_subparsers() copies the relevant arguments through to constructed
subparsers."
Obligation: inheritance belongs in subparser construction, not in global command
execution error handling. Status: encoded by PO1 and PO7.

E4. Source: `repo/django/core/management/base.py`.
Quote: `CommandParser.error()` delegates to `super().error()` only when
`called_from_command_line` is true; otherwise it raises `CommandError`.
Obligation: the formal model must distinguish CLI mode from programmatic mode.
Status: encoded by PO1 and PO2.

E5. Source: `repo/django/core/management/base.py`.
Quote: `run_from_argv()` sets `_called_from_command_line = True` before
creating the parser, while `BaseCommand._called_from_command_line` defaults to
`False`.
Obligation: top-level parser construction is the source of the mode bit that
subparsers must inherit. Status: encoded by PO1 and PO2.

E6. Source: `repo/django/core/management/__init__.py`.
Quote: `call_command()` creates a parser and calls `parser.parse_args()` to
simulate defaults.
Obligation: programmatic parsing still needs `CommandError`, not `SystemExit`.
Status: encoded by I3 and PO2.

E7. Source: `repo/django/core/management/base.py`.
Quote: `missing_args_message` is read by `CommandParser.parse_args()` before
normal argparse parsing.
Obligation: do not treat the command-level message as an inherited child-parser
postcondition without separate intent evidence. Status: encoded by I5 and PO6.

## Formal Model

The proof abstracts Python and argparse to the behavior relevant to the issue.

State symbols:

- `CP(mode, missing)` is a Django `CommandParser`.
- `AP` is any non-Django parser class or parser factory.
- `Action(factory)` is the subparser action returned by `add_subparsers()`.
- `Child(mode, missing)` is a constructed Django child parser.
- `Kw(k, v)` is a child-parser keyword argument supplied to `add_parser()`.
- `ErrCLI(msg)` is argparse's command-line usage/error exit behavior.
- `ErrProgrammatic(msg)` is Django's `CommandError("Error: ...")` behavior.

Transition summary:

```text
add_subparsers(CP(mode, missing), kwargs_without_parser_class)
  => Action(wrapper(CommandParser, called_from_command_line = mode))

add_subparsers(CP(mode, missing), kwargs_with_parser_class = DjangoSubclass)
  => Action(wrapper(DjangoSubclass, called_from_command_line = mode))

add_subparsers(CP(mode, missing), kwargs_with_parser_class = AP)
  => Action(AP)

add_parser(Action(wrapper(C, inherited_mode)), child_kwargs)
  => C(child_kwargs with called_from_command_line defaulting to inherited_mode)

error(CP(True, _), msg) => ErrCLI(msg)
error(CP(False or None, _), msg) => ErrProgrammatic(msg)
```

The wrapper uses a default, not an override: if `child_kwargs` already contains
`called_from_command_line`, that explicit child value wins.

## Claims

C1. For any Django `CommandParser` parent in CLI mode, any Django child parser
created through `add_subparsers().add_parser()` has `called_from_command_line`
true unless explicitly overridden by child kwargs.

C2. For any Django `CommandParser` parent in programmatic mode, any Django child
parser created through `add_subparsers().add_parser()` has
`called_from_command_line` false unless explicitly overridden by child kwargs.

C3. For any child parser satisfying C1, `child.error(message)` follows
argparse's command-line usage/error path and does not raise uncaught
`CommandError`.

C4. For any child parser satisfying C2, `child.error(message)` raises
`CommandError`, preserving `call_command()` behavior.

C5. Nested Django subparsers satisfy C1 and C2 by induction, because each child
parser is itself a `CommandParser` and therefore applies the same
`add_subparsers()` rule.

C6. A caller-supplied non-Django `parser_class` is not wrapped, replaced, or
given Django-specific keyword arguments.

C7. `missing_args_message` is not inherited by default. A subparser receives a
`missing_args_message` only if its own `add_parser()` kwargs provide one.

## Adequacy Audit

The formal model captures the property the issue reports: the mode bit used by
`CommandParser.error()` is absent on child parsers, causing CLI child parser
errors to take the programmatic `CommandError` path. It intentionally omits
unrelated argparse details such as option tokenization and help text formatting;
those are not the changed state and do not distinguish the failing and passing
cases for this issue.

C1-C5 match I1-I3. C6 matches I4. C7 matches I5. No claim is derived solely
from V1 behavior.
