# Baseline Notes

## Root cause

`BaseCommand.create_parser()` creates the top-level management command parser as
`CommandParser(called_from_command_line=True)` when a command is invoked through
`run_from_argv()`. `CommandParser.error()` uses that flag to delegate to
`argparse.ArgumentParser.error()`, which prints usage and exits cleanly.

Subparsers created with `parser.add_subparsers().add_parser()` were also
instances of `CommandParser`, but argparse constructed them without Django's
`called_from_command_line` value. When a subparser reported an argument error,
its `called_from_command_line` attribute was `None`, so `CommandParser.error()`
raised `CommandError`. Because this happens during `run_from_argv()` parsing,
before the command execution `CommandError` handler, the exception surfaced as a
traceback instead of a normal CLI usage error.

## Changed files

`repo/django/core/management/base.py`

Added `CommandParser.add_subparsers()` so that, when Django's `CommandParser` or
a subclass is used for subcommands, child parsers inherit the parent's
`called_from_command_line` value by default. Explicit `called_from_command_line`
values passed to `add_parser()` are left intact, and non-`CommandParser`
`parser_class` values are preserved.

`reports/baseline_notes.md`

Recorded the root cause, implementation details, assumptions, and rejected
alternatives as requested by the benchmark task.

## Assumptions and alternatives considered

I assumed the CLI behavior should match top-level parser errors: subparser
argument errors should print argparse usage and exit without a Python traceback
when invoked from the command line, while programmatic `call_command()` usage
should continue to raise `CommandError`.

I considered copying `missing_args_message` from the parent parser into every
subparser as well, but rejected it. That message describes the command-level
case where no positional argument was supplied. Once a subcommand has been
selected, reusing the parent message for the child parser could replace a
specific subcommand error such as a missing subcommand argument with an
unrelated command-level message. The fix therefore propagates only the error
mode flag that caused the traceback.

I also considered changing `run_from_argv()` to catch `CommandError` around
argument parsing, but rejected it because it would broaden command-line parsing
behavior globally. Keeping the fix in `CommandParser.add_subparsers()` targets
only parser instances created through Django's management command parser.
