# FVK Findings

Status: constructed, not machine-checked. Findings are based only on public issue text, source inspection, and proof-obligation reasoning.

## F1: Reported `ManagementUtility` early parser bug

- Classification: code bug, resolved by V1 and retained in V2.
- Evidence: SPEC E1-E4; proof obligations PO1-PO3.
- Input shape: global `sys.argv[0]` is invalid, but caller invokes `execute_from_command_line(['embedded-admin', 'help'])` or `execute_from_command_line(['embedded-admin', '--settings', 'x', 'help'])`.
- Observed before the fix: the early `CommandParser` omitted `prog`, so parser construction/usage formatting could consult global `sys.argv[0]` even though `ManagementUtility` had already computed `self.prog_name` from explicit `argv`.
- Expected: the early parser uses `self.prog_name`, making this bootstrap phase independent of global `sys.argv[0]`.
- Resolution: `repo/django/core/management/__init__.py` now passes `prog=self.prog_name`.

## F2: V1 missed an adjacent explicit-argv pre-parser

- Classification: code bug in V1, resolved in V2.
- Evidence: SPEC E4-E5; proof obligation PO4.
- Input shape: global `sys.argv[0]` is invalid, caller supplies explicit management `argv`, and the dispatched command is `test`, whose `run_from_argv()` calls `get_command_line_option(argv, '--testrunner')`.
- Observed in V1: `get_command_line_option()` constructed `CommandParser(add_help=False, allow_abbrev=False)` without `prog`, even though its own documented input is an argument list. This retained the same kind of global `sys.argv[0]` dependency for a reachable management-command preparse.
- Expected: parser construction derives `prog` from the helper's explicit `argv`, or a stable empty program string when `argv` is empty.
- Resolution: `repo/django/core/management/utils.py` now computes `prog_name = os.path.basename(argv[0]) if argv else ''` and passes `prog=prog_name`.

## F3: Command-specific parsers already satisfy the obligation

- Classification: no code change.
- Evidence: SPEC E6; proof obligation PO5.
- Input shape: any normal command dispatch through `BaseCommand.run_from_argv(argv)`.
- Observed: `BaseCommand.create_parser()` passes explicit `prog='%s %s' % (os.path.basename(prog_name), subcommand)`.
- Expected: no dependency on global `sys.argv[0]` for command-specific parser construction.
- Resolution: no change made to `BaseCommand` or `CommandParser`.

## F4: Verification and test-redundancy are limited by the environment

- Classification: proof capability/environment gap, not a code bug.
- Evidence: user instruction forbids running tests, Python, or K tooling.
- Observed: no executable validation or machine-checked `kprove` result is available.
- Expected: artifacts document the commands and constructed proof, and tests remain untouched.
- Resolution: all proof claims are labeled constructed, not machine-checked; no tests are removed or modified.

## Open Findings

No open source-code findings remain within this spec's domain after V2. Residual risk is outside the modeled slice: arbitrary command execution, settings import side effects, and the behavior when the caller-provided `argv[0]` itself is invalid.
