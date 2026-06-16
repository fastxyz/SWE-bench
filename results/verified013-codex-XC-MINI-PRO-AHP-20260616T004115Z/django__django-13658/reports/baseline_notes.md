# Baseline Notes

## Root cause

`ManagementUtility.__init__()` stores the command name in `self.prog_name` from the `argv` passed to the utility. This allows callers of `execute_from_command_line(argv)` to avoid relying on the process-global `sys.argv`.

During `ManagementUtility.execute()`, Django creates an early `CommandParser` to parse `--settings` and `--pythonpath` before loading commands. That parser did not receive an explicit `prog`, so `argparse.ArgumentParser` inferred the program name from global `sys.argv[0]`. In embedded or programmatic environments where `sys.argv[0]` is invalid, this defeated the caller-provided `argv` and could produce invalid usage/error text or exceptions before command dispatch.

## Changed files

`repo/django/core/management/__init__.py`

Passed `prog=self.prog_name` to the preliminary `CommandParser` in `ManagementUtility.execute()`. This keeps the early parser consistent with the rest of `ManagementUtility`, which already uses `self.prog_name` for help and error messages.

## Assumptions

The issue is limited to the early parser used for global option preprocessing. Command-specific parsers already derive their program names from the command `argv` passed through `run_from_argv()`, and the help paths in `ManagementUtility` already use `self.prog_name`.

I did not modify tests because the benchmark instructions require changing non-test source code only, and I did not run tests or execute project code because the session instructions prohibit it.

## Alternatives considered

One alternative was to change `CommandParser` so every parser without an explicit `prog` derives it differently. I rejected that because it would affect unrelated management parsers and normal `argparse` behavior.

Another alternative was to mutate `sys.argv[0]` from `ManagementUtility.__init__()`. I rejected that because the reported problem is specifically that callers should be able to pass `argv` without changing process-global state.
