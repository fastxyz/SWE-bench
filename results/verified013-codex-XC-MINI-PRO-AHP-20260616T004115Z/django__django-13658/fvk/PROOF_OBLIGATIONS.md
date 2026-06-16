# FVK Proof Obligations

Status: constructed, not machine-checked.

## Model

The model abstracts only the observable property under audit: which program name is supplied to each management pre-parser. It deliberately frames away command loading, settings imports, and arbitrary command execution.

Symbols:

- `ARGV0`: the first element of caller-provided management `argv`.
- `SYS0`: process-global `sys.argv[0]`, which may be invalid.
- `basename(ARGV0)`: the program-name extraction performed by the code.
- `mgmt_prog(ARGV0)`: `python -m django` if `basename(ARGV0) == '__main__.py'`, otherwise `basename(ARGV0)`.
- `helper_prog(argv)`: `basename(argv[0])` if `argv` is non-empty, otherwise `''`.
- `parser.prog`: the explicit `prog` received by `CommandParser`/`ArgumentParser`.

## PO1: ManagementUtility program-name source

Precondition:

- Explicit `argv` is non-empty and `argv[0]` is a valid path-like value.

Obligation:

```text
ManagementUtility(argv).__init__
  => self.argv == argv
  => self.prog_name == mgmt_prog(argv[0])
```

Rationale:

This establishes the intent-derived source of truth for the later parser. It is supported by SPEC E1 and existing code.

Status: discharged by source inspection.

## PO2: Early management parser uses `self.prog_name`

Precondition:

- PO1 holds.
- `SYS0` may be invalid.

Obligation:

```text
ManagementUtility(argv).execute early-preparse
  constructs CommandParser(
      prog=self.prog_name,
      usage='%(prog)s subcommand [options] [args]',
      add_help=False,
      allow_abbrev=False,
  )
```

Postcondition:

```text
parser.prog == self.prog_name
parser construction does not need SYS0
```

Status: discharged by V2 source at `repo/django/core/management/__init__.py`.

## PO3: Early management parser frame conditions

Obligation:

The PO2 edit must preserve all non-`prog` behavior:

```text
registered options == {'--settings', '--pythonpath', 'args'}
parse input == self.argv[2:]
allow_abbrev == False
add_help == False
on successful parse => handle_default_options(options)
on CommandError => ignore at this phase
```

Status: discharged by diff inspection; only the parser construction gained `prog`.

## PO4: `get_command_line_option()` parser uses its explicit argument list

Precondition:

- `argv` is any list-like argument vector accepted by the existing helper.
- `SYS0` may be invalid.

Obligation:

```text
get_command_line_option(argv, option)
  prog_name := basename(argv[0]) if argv else ''
  constructs CommandParser(prog=prog_name, add_help=False, allow_abbrev=False)
  parses argv[2:]
```

Postcondition:

```text
parser.prog == helper_prog(argv)
parser construction does not need SYS0
return value behavior remains:
  matching option value if parse succeeds and option is present
  None if option absent or parsing raises CommandError
```

Status: discharged by V2 source at `repo/django/core/management/utils.py`.

## PO5: Command-specific parser compatibility

Obligation:

No broad `CommandParser` constructor change is required if public command-specific parser construction already supplies explicit `prog`.

Evidence:

```text
BaseCommand.create_parser(prog_name, subcommand)
  constructs CommandParser(prog='%s %s' % (os.path.basename(prog_name), subcommand), ...)
```

Status: discharged by source inspection; no source change made.

## PO6: No global-state mutation

Obligation:

The fix must not repair the issue by assigning to `sys.argv[0]` or otherwise mutating global process state.

Status: discharged by diff inspection; both changes pass explicit `prog` to parser constructors and do not write to `sys.argv`.
