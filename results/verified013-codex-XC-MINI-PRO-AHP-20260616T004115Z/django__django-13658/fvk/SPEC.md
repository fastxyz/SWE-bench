# FVK Spec: management argv parser program name

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 fix for `django__django-13658` and the adjacent management pre-parser path that has the same observable dependency:

- `repo/django/core/management/__init__.py`: `ManagementUtility.__init__()` and the early `CommandParser` in `ManagementUtility.execute()`.
- `repo/django/core/management/utils.py`: `get_command_line_option(argv, option)`, used by the `test` command to preparse a caller-provided command line.

Command-specific parsers produced by `BaseCommand.create_parser()` are in the compatibility/frame scope because they already receive an explicit `prog`.

## Intent Specification

1. When a caller passes an explicit `argv` to Django's management entry point, management bootstrapping must use that argument vector's program name instead of process-global `sys.argv[0]`.
2. The early parser for `--settings` and `--pythonpath` must be constructible and usable even when global `sys.argv[0]` is invalid, provided the caller supplied a valid `argv[0]`.
3. `%(prog)s` in the early parser usage string must expand to `ManagementUtility.prog_name`.
4. No fix should mutate global `sys.argv`, change command dispatch, change option names, or change the semantics of `--settings`, `--pythonpath`, or command-specific option parsing.
5. A helper whose documented contract is to parse "an argument list" should not need process-global `sys.argv[0]` merely to construct its parser.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | issue | "`ManagementUtility` goes to the trouble to parse the program name from the argv it's passed rather than from `sys.argv`" | `self.prog_name` is the intended program-name source for explicit `argv`. | Encoded by C1. |
| E2 | issue | "when it needs to parse `--pythonpath` and `--settings`, it uses the program name from `sys.argv`" | The early options parser is the reported failing contributor. | Encoded by C2. |
| E3 | issue | "`%(prog)s` refers to `sys.argv[0]`. Instead, it should refer to `self.prog_name`." | Parser construction must pass `prog=self.prog_name`. | Encoded by C2. |
| E4 | issue | "If passing my own argv to `execute_from_command_line` avoided all the ensuing exceptions..." | For explicit management argv, parser construction must be independent of invalid global `sys.argv[0]`. | Encoded by C2 and C4. |
| E5 | source/docstring | `get_command_line_option(argv, option)` returns a value "from an argument list." | The helper's parser should be anchored to its `argv`, not to global `sys.argv[0]`, while preserving return behavior. | Encoded by C4. |
| E6 | source | `BaseCommand.create_parser()` constructs `CommandParser(prog='%s %s' % (os.path.basename(prog_name), subcommand), ...)`. | Command-specific parsers already satisfy explicit-program-name framing. | Encoded by C5. |

## Domain and Preconditions

- In the reported management-entry domain, explicit `argv` is non-empty and `argv[0]` is a valid path-like program name. The issue is not asking Django to repair an invalid caller-provided `argv[0]`.
- If `argv` is omitted, `ManagementUtility` keeps its existing behavior of copying `sys.argv[:]`; that path is outside the reported explicit-argv guarantee.
- Global `sys.argv[0]` may be invalid in the reported embedded environment. The audited pre-parsers must not need it once explicit `argv` exists.
- This FVK pass proves partial correctness of the parser-construction and preparse dataflow only. It does not prove command execution, settings import success, process exit behavior, or termination of arbitrary commands.

## Formal Claims in English

| Claim | Statement | Provenance |
| --- | --- | --- |
| C1 | For explicit management `argv`, `ManagementUtility.__init__()` computes `self.prog_name` from `os.path.basename(argv[0])`, except `__main__.py` maps to `python -m django`. | E1 |
| C2 | In `ManagementUtility.execute()`, the parser used to preparse `--settings` and `--pythonpath` is constructed with `prog=self.prog_name`; therefore parser construction and `%(prog)s` usage expansion do not consult global `sys.argv[0]`. | E2, E3, E4 |
| C3 | The C2 change preserves the parse input `self.argv[2:]`, registered arguments, `allow_abbrev=False`, `add_help=False`, `handle_default_options(options)`, and the `CommandError` catch behavior. | E4 frame condition |
| C4 | In `get_command_line_option(argv, option)`, the parser is constructed with `prog=os.path.basename(argv[0])` when `argv` is non-empty, otherwise with `prog=''`; it still parses `argv[2:]` and returns the option value or `None`. | E5 |
| C5 | No source change is needed in `BaseCommand.create_parser()` because it already passes explicit `prog` from `run_from_argv()`/callers. | E6 |

## Adequacy Audit

| Formal claim | Intent match | Result |
| --- | --- | --- |
| C1 | Matches E1 and existing code. It is a precondition source, not a new behavior. | Pass |
| C2 | Directly matches the issue's requested fix. | Pass |
| C3 | Preserves public behavior outside the `prog` source. | Pass |
| C4 | Extends the same explicit-argv independence to a documented helper that parses an argument list and is reachable from management command dispatch. | Pass |
| C5 | Prevents an unnecessary broad rewrite of command parser creation. | Pass |

No formal claim is derived solely from V1 behavior. C4 is the only V2 expansion beyond V1; it is justified by E4 and E5 and recorded as Finding F2.

## Public Compatibility Audit

- `ManagementUtility.execute()` has no signature change and still constructs a `CommandParser` with the same options and usage string.
- `get_command_line_option(argv, option)` has no signature or return-type change. Empty `argv` remains tolerated; the helper now uses an empty program name instead of allowing `argparse` to infer from global state.
- `CommandParser` itself is not changed. Third-party management commands and subclasses are not required to accept new arguments or override new methods.
- No test files are modified.
