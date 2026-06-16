# FVK Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Adequacy Gate

The public issue requires command-line subparser argument errors to use
human-facing argparse usage formatting rather than leaking a traceback. The
source shows that `CommandParser.error()` chooses that behavior solely from the
`called_from_command_line` attribute. Therefore the proof focuses on whether
child `CommandParser` instances inherit that mode during
`add_subparsers().add_parser()` construction.

The proof does not model unrelated argparse internals such as tokenization,
choice rendering, or help text layout. Those details do not distinguish the
reported failing behavior from the intended behavior; the distinguishing state
is the child parser's error mode.

## Constructed Proof

PO1, CLI mode propagation:

1. In CLI invocation, `BaseCommand.run_from_argv()` sets
   `_called_from_command_line = True` before `create_parser()`.
2. `create_parser()` passes that value into the top-level `CommandParser`.
3. `CommandParser.add_subparsers()` reads the parser class that argparse will
   use. When omitted, this is `type(self)`, a Django `CommandParser` class.
4. Because the parser class is a `CommandParser` class, V2 stores the current
   `called_from_command_line` value in a local variable and installs a wrapper
   parser factory.
5. The wrapper calls `setdefault("called_from_command_line", True)` before
   constructing the child parser.
6. Therefore any child parser without an explicit override is constructed with
   `called_from_command_line = True`.

PO2, programmatic mode propagation:

1. `BaseCommand._called_from_command_line` defaults to `False`.
2. `call_command()` creates a parser without calling `run_from_argv()`, so the
   top-level parser's mode is false.
3. The same wrapper construction as PO1 snapshots false.
4. The wrapper calls `setdefault("called_from_command_line", False)` before
   constructing the child parser.
5. Therefore any child parser without an explicit override is constructed with
   `called_from_command_line = False`.

PO3, error behavior:

1. `CommandParser.error()` delegates to `argparse.ArgumentParser.error()` when
   `called_from_command_line` is truthy.
2. For PO1 children, the mode is true, so a missing required child argument
   reaches argparse's usage/error path.
3. `CommandParser.error()` raises `CommandError("Error: ...")` otherwise.
4. For PO2 children, the mode is false, so programmatic parsing still raises
   `CommandError`.

PO4, non-Django parser-class frame:

1. V2 reads `parser_class = kwargs.get("parser_class", type(self))`.
2. It mutates `kwargs["parser_class"]` only inside the branch where
   `parser_class` is a class and a subclass of `CommandParser`.
3. If a caller supplies a non-Django class, factory, or other value, the branch
   is not taken.
4. Therefore the value is delegated to argparse unchanged.

PO5, explicit child kwarg precedence:

1. The wrapper uses `dict.setdefault()`, not assignment.
2. If `add_parser()` already supplied `called_from_command_line`, the existing
   child value remains.
3. Therefore inherited mode is a default only.

PO6, missing-args-message frame:

1. The wrapper only sets `called_from_command_line`.
2. It does not copy `missing_args_message`.
3. Therefore a child parser receives no inherited command-level missing message
   unless `add_parser()` explicitly supplies one.

PO7, locality:

1. The only source edit is inside `CommandParser.add_subparsers()`.
2. `run_from_argv()`, `call_command()`, and `CommandParser.error()` retain their
   existing control flow.
3. Therefore the repair changes only the construction of child Django parsers,
   matching the public issue's proposed correction point.

## Findings Trace

F1 is discharged by PO1, PO3, and PO7.

F2 is discharged by PO2 and PO3.

F3 is discharged by PO4.

F4 is discharged by PO1 and the snapshot step in the PO1 proof.

F5 is discharged by PO6.

F6 remains an honesty constraint: the proof is constructed, not
machine-checked.

## Residual Risk

This proof is partial correctness over an abstract parser-construction model.
It does not prove termination, although the edited method has no loops and only
delegates to argparse after a finite branch.

The trusted base is the adequacy of the abstraction: `called_from_command_line`
is the relevant state controlling the observed traceback, and argparse's own
error machinery behaves as Django already relies on for top-level command-line
parsers.

## Test Guidance

No tests were run or modified.

Recommended tests to keep or add after this patch:

- A CLI regression command with `add_subparsers(required=True)`, a child parser
  requiring a positional argument, and an invocation equivalent to
  `manage.py cheeses create`, asserting usage output and no traceback.
- A programmatic `call_command()` regression for a missing child subparser
  argument, asserting `CommandError`.
- A nested subparser regression mirroring `subparser_required`, asserting the
  innermost required option uses the correct mode.

Any test-removal recommendation is conditioned on materializing and
machine-checking the K claims from `fvk/PROOF_OBLIGATIONS.md` and receiving
`#Top` from `kprove`.

## Recorded Verification Commands

The following commands are the intended machine-check path and were not run:

```sh
kompile fvk/mini-command-parser.k --backend haskell
kast --backend haskell fvk/command-parser-spec.k
kprove fvk/command-parser-spec.k
```
