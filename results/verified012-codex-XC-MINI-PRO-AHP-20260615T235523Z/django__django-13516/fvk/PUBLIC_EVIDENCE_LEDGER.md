# Public Evidence Ledger

Status: constructed for FVK audit; not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "`flush()` on self.stdout/stderr management commands doesn't work." | `OutputWrapper.flush()` must make command stdout/stderr flush calls effective. | Encoded by PO-1 and claim `FLUSH-DELEGATES`. |
| E2 | prompt | Long migration shows no progress until the end; expected output shows `Applying ...` before work and `OK` after. | A write with `ending=""` followed by flush must make the partial progress line visible before later output. | Encoded by PO-3 and claim `PARTIAL-WRITE-THEN-FLUSH`. |
| E3 | implementation | `migrate.py` writes `Applying`, `Unapplying`, and `Rendering model states` with `ending=""`, then calls `self.stdout.flush()` at lines 278-301. | The affected observable is partial-line progress output followed by explicit flush. | Used to localize the formal target. |
| E4 | implementation | `BaseCommand.__init__()` wraps stdout/stderr in `OutputWrapper` at lines 243-245; `execute()` rewraps option streams at lines 386-389. | Fixing `OutputWrapper` reaches default and custom command streams. | Encoded by compatibility audit C-1. |
| E5 | implementation | `OutputWrapper.__getattr__()` delegates unknown attributes at lines 140-141, but `TextIOBase` already supplies `flush()`. | Pre-V1 `flush()` did not delegate through `__getattr__`; V1 must override `flush()` explicitly. | Recorded as Finding F-1. |
| E6 | public-test | `test_custom_stdout` and `test_custom_stderr` use `StringIO` and assert write output at `tests/admin_scripts/tests.py` lines 1542-1572. | Custom stream write behavior is a frame condition; the fix must not change the wrapping API or write formatting. | Encoded by PO-4 and compatibility audit C-2. |
| E7 | candidate code | V1 adds `OutputWrapper.flush()` at `base.py` lines 146-148. | Candidate behavior should delegate to `_out.flush()` if present and otherwise leave the stream alone. | Encoded by PO-1 and PO-2. |

No hidden tests, upstream fix, benchmark result files, or internet evidence were used.
