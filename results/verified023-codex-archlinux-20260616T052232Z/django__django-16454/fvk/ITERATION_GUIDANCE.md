# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1's core repair was directionally correct: child Django parsers need the
parent parser's `called_from_command_line` mode. The FVK audit found two small
compatibility refinements, both applied in V2:

- mutate `parser_class` only for Django `CommandParser` classes or subclasses;
- snapshot `called_from_command_line` before installing the wrapper factory.

No further source changes are recommended by the current proof obligations.

## Next Code Iteration

Keep `repo/django/core/management/base.py` focused on parser construction.
Avoid broadening the fix into `run_from_argv()` or `call_command()` unless a
new public intent source shows those paths are independently wrong.

Do not automatically propagate `missing_args_message` to subparsers. A child
parser that needs a custom missing-argument message can pass its own
`missing_args_message` through `add_parser()`; inheriting the command-level
message would risk replacing subparser-specific errors with unrelated
command-level text.

## Next Test Iteration

Do not edit tests in this benchmark. For a normal Django patch, add focused
coverage for:

- CLI invocation with a selected subparser missing a required positional
  argument;
- CLI invocation with nested subparsers missing an innermost required option;
- programmatic `call_command()` preserving `CommandError` for child parser
  errors.

## Formal Verification Iteration

If a strict FVK runner is available later, materialize the abstract semantics
from `fvk/PROOF_OBLIGATIONS.md` into:

- `fvk/mini-command-parser.k`
- `fvk/command-parser-spec.k`

Then run the recorded commands:

```sh
kompile fvk/mini-command-parser.k --backend haskell
kast --backend haskell fvk/command-parser-spec.k
kprove fvk/command-parser-spec.k
```

Expected result: `#Top` for the abstract claims. Until that happens, the proof
remains constructed, not machine-checked, and no test removal should be based
on it.
