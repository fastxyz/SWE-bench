# FVK Iteration Guidance

Status: V2 should stand within the audited spec.

## Decisions

1. Keep the V1 `ManagementUtility.execute()` change.
   - Basis: FINDINGS F1, PROOF_OBLIGATIONS PO1-PO3.
   - Reason: it is the issue's direct requested behavior and preserves all non-`prog` preparse behavior.

2. Add the V2 `get_command_line_option()` change.
   - Basis: FINDINGS F2, PROOF_OBLIGATIONS PO4.
   - Reason: the helper parses an explicit argument list and was reachable from the `test` management command before command-specific parser creation. Leaving it unchanged would preserve a second parser-construction dependency on invalid global `sys.argv[0]`.

3. Do not change `CommandParser` globally.
   - Basis: FINDINGS F3, PROOF_OBLIGATIONS PO5.
   - Reason: the intent is to anchor explicit-argv pre-parsers to their explicit argv. A global `CommandParser` policy change would be broader than the issue and could affect unrelated callers.

4. Do not mutate `sys.argv`.
   - Basis: PROOF_OBLIGATIONS PO6.
   - Reason: the public issue explicitly wants caller-provided `argv` to avoid modifying global state.

## Next Tests to Add in a Normal Development Environment

Do not add or edit tests in this benchmark. In a normal Django development environment, add focused regression tests for:

- Early `ManagementUtility` parsing with explicit `argv` and invalid global `sys.argv[0]`.
- `get_command_line_option()` with explicit `argv`, including a `test --testrunner` shape, under invalid global `sys.argv[0]`.
- A frame case confirming existing option extraction still returns the requested value and returns `None` when absent.

## What Not to Do Next

- Do not broaden the fix to all `argparse.ArgumentParser` users without a separate public-intent finding.
- Do not change `ManagementUtility.__init__()` fallback behavior for `argv=None`; that path intentionally uses `sys.argv[:]`.
- Do not claim machine-checked proof confidence until the K commands in `PROOF.md` have actually been run in an environment with K installed.
