# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| INT-1 | problem | "`caplog.get_records()` gets decoupled from actual caplog records when `caplog.clear()` is called" | `clear` must preserve coupling between current phase stash records and handler records. | Encoded in `CLEAR-CURRENT` and `CLEAR-THEN-EMIT`. |
| INT-2 | problem | Reproduction expects `caplog.get_records("call") == caplog.records` after `caplog.clear()`. | Both views must observe the same current records contents after clear. | Encoded in `CLEAR-CURRENT`. |
| INT-3 | problem | After clear, `get_records()` "does not get new records" is reported as the bug. | Emits after clear must append to the list visible through `get_records(when)`. | Encoded in `CLEAR-THEN-EMIT`. |
| INT-4 | docstring | `get_records` returns records for `"setup"`, `"call"` and `"teardown"` stages. | Phase transition reset must preserve older phase records. | Encoded in `BEGIN-PHASE-PRESERVES-PREVIOUS`. |
| INT-5 | fixture docs | `caplog.clear()` clears captured records and formatted log output string. | Clear records and text content. | Encoded in `CLEAR-CURRENT`; text content only, no public stream-identity obligation. |
| CODE-1 | implementation | `_runtest_for` calls `caplog_handler.reset()` then stores `caplog_handler.records` in `item.stash[caplog_records_key][when]`. | The model must represent list object identity and phase stash references. | Used as implementation semantics, not as intent. |
| CODE-2 | implementation | `emit` appends to `self.records`; `caplog.records` returns `self.handler.records`. | The model must represent append to the handler's current records reference. | Used as implementation semantics. |
