# FVK Notes

## Source decisions

Kept the V1 change in `repo/django/core/management/__init__.py`.

- Trace: `fvk/FINDINGS.md` F1; `fvk/PROOF_OBLIGATIONS.md` PO1-PO3.
- Reason: the public issue directly requires the early `ManagementUtility` parser to use the already-computed `self.prog_name`. The proof obligations show the change eliminates the global `sys.argv[0]` dependency while preserving the rest of the early parse behavior.

Added a V2 change in `repo/django/core/management/utils.py`.

- Trace: `fvk/FINDINGS.md` F2; `fvk/PROOF_OBLIGATIONS.md` PO4.
- Reason: FVK's completeness pass found that `get_command_line_option(argv, option)` also parses an explicit argument list but constructed `CommandParser` without `prog`. It is reachable from the `test` management command before command-specific parser construction, so leaving it unchanged would preserve the same class of global `sys.argv[0]` dependency for that path.

Left `CommandParser` and `BaseCommand.create_parser()` unchanged.

- Trace: `fvk/FINDINGS.md` F3; `fvk/PROOF_OBLIGATIONS.md` PO5.
- Reason: command-specific parsers already pass explicit `prog`, and changing `CommandParser` globally would be broader than the public issue.

Did not mutate `sys.argv`.

- Trace: `fvk/PROOF_OBLIGATIONS.md` PO6.
- Reason: the issue's desired workaround is passing explicit `argv`, not modifying global process state.

## Verification decisions

The proof is recorded as constructed, not machine-checked.

- Trace: `fvk/FINDINGS.md` F4; `fvk/PROOF.md`.
- Reason: the task forbids running tests, Python, or K tooling. The K commands are written in `fvk/PROOF.md` for later reproduction but were not executed.

No tests were changed.

- Trace: `fvk/FINDINGS.md` F4; `fvk/ITERATION_GUIDANCE.md`.
- Reason: the benchmark fixes source only and treats the test suite as fixed/hidden.
