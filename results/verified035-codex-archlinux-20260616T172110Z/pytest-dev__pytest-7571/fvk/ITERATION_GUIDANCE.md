# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Verdict

V1 stands unchanged. The FVK audit found the original bug as F-1 and the V1
source change discharges the associated proof obligations PO-2, PO-3, and PO-6.
No additional source edit is justified by the public intent, compatibility
audit, or constructed proof.

## Guidance For A Future Execution-Enabled Pass

1. Run the emitted K commands from `fvk/PROOF.md`.
2. Run the pytest logging tests in an execution environment.
3. Add or confirm a regression test equivalent to the issue reproduction:
   `test_foo` calls `caplog.set_level(42)`, and a later test asserts
   `caplog.handler.level == 0` in the default configuration.
4. Keep existing caplog tests until the K proof is machine-checked and normal CI
   passes.

## Code Guidance

Do not move the restoration into `catching_logs.__exit__()` unless a separate
public issue requires a broader logging-handler lifecycle change. F-4 explains
why fixture finalization is the targeted location for this bug.

Do not change `caplog.at_level()` for this issue. F-3 and PO-5 show it already
has block-scoped handler restoration.

Do not hard-code `0` as the restored handler level. PO-6 requires restoring the
observed original level so configured `log_level` behavior remains valid.

## Open Questions

No user clarification is required for the current issue. The documentation and
minimal reproduction identify the required behavior precisely enough: levels set
through `caplog.set_level()` must be restored at test end.
