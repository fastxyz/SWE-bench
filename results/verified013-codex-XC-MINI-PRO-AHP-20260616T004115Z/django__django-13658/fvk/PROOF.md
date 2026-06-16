# FVK Proof

Status: constructed, not machine-checked. No tests, Python code, `kompile`, `kast`, or `kprove` were executed.

## Claims Proved

1. For explicit management `argv`, the early `ManagementUtility.execute()` parser receives `prog=self.prog_name`, so it does not consult invalid global `sys.argv[0]` for parser construction or `%(prog)s` expansion.
2. `get_command_line_option(argv, option)` now constructs its pre-parser with a program name derived from its explicit `argv`, preserving the helper's return behavior while eliminating the same global `sys.argv[0]` dependency.
3. Command-specific parsers already pass explicit `prog`, so no `BaseCommand` or `CommandParser` API change is needed.

## Constructed Proof

PO1 follows from `ManagementUtility.__init__()`: for explicit non-empty `argv`, `self.argv` is set to `argv`, `self.prog_name` is set to `os.path.basename(self.argv[0])`, and `__main__.py` is normalized to `python -m django`.

For PO2, the V2 source constructs the early parser as:

```python
CommandParser(
    prog=self.prog_name,
    usage='%(prog)s subcommand [options] [args]',
    add_help=False,
    allow_abbrev=False,
)
```

`CommandParser.__init__()` forwards unconsumed keyword arguments to `argparse.ArgumentParser` via `super().__init__(**kwargs)`. Because `prog` is explicit, the parser has no need to infer its program name from global `sys.argv[0]`. By PO1, that explicit value is exactly the caller-argv-derived program name required by SPEC E1-E4.

PO3 is a frame proof over the diff: the registered arguments, parse input `self.argv[2:]`, `handle_default_options(options)`, and `CommandError` handling are unchanged. Therefore the only changed observable in this preparse phase is the source of parser `prog`.

PO4 follows from the V2 `utils.py` edit. The helper computes `prog_name = os.path.basename(argv[0]) if argv else ''`, constructs `CommandParser(prog=prog_name, add_help=False, allow_abbrev=False)`, adds the same requested option, and still parses `argv[2:]`. The `try`/`except CommandError` and return statements are unchanged, so successful option extraction and `None` fallback behavior are preserved while parser construction no longer depends on global `sys.argv[0]`.

PO5 follows from existing `BaseCommand.create_parser()`, which already constructs command-specific parsers with explicit `prog` from `prog_name` and `subcommand`. A broad `CommandParser` default change would affect unrelated parser users and is not needed to discharge the issue.

PO6 follows from diff inspection: neither source change writes to `sys.argv` or mutates process-global state.

## Machine Check Commands Not Run

The corresponding K-style abstract obligations are represented by `fvk/PROOF_OBLIGATIONS.md`, `fvk/mini-management.k`, and `fvk/management-preparse-spec.k`. In a full FVK environment, the commands would be:

```sh
kompile fvk/mini-management.k --backend haskell
kast --backend haskell fvk/management-preparse-spec.k
kprove fvk/management-preparse-spec.k
```

Expected constructed result: all obligations reduce to `#Top` because each claim is a direct dataflow property over explicit `prog` arguments and unchanged framed parser behavior.

## Test Guidance

No test files were inspected or modified. Because this proof is constructed, not machine-checked, no test-removal recommendation is made. Useful regression tests, if the fixed suite were editable, would cover:

- `ManagementUtility(['embedded-admin', '--settings', 'pkg.settings', 'help'])` with invalid global `sys.argv[0]` still constructing the early parser with `embedded-admin`.
- `execute_from_command_line(['embedded-admin', 'test', '--testrunner', 'pkg.Runner'])` reaching `get_command_line_option()` without relying on global `sys.argv[0]`.

## Residual Risk

This proof covers parser construction and preparse dataflow only. It does not prove arbitrary management command behavior, settings import behavior, process exits, or total correctness. It also assumes the caller-provided explicit `argv[0]` is valid; repairing invalid explicit `argv` is outside the public issue.
