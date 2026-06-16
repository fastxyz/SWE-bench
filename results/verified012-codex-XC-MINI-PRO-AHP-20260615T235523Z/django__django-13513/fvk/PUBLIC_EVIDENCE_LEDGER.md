# Public Evidence Ledger

| ID | Source | Quoted evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "debug error view doesn't respect exc.__suppress_context__ (PEP 415)" | The traceback reporter must use `__suppress_context__` when deciding whether `__context__` is visible. | Encoded in PO1 and K claim `resolve(none, true, OLD) => none`. |
| E2 | `benchmark/PROBLEM.md` | "`raise ValueError('my new error') from None`" | `raise ... from None` is the concrete suppressed-context case. | Encoded in the issue-chain claim and FINDING F1. |
| E3 | `benchmark/PROBLEM.md` | "the debug error view still shows the RuntimeError" | The legacy observable is wrong: the handled `RuntimeError` must be excluded. | Encoded as pre-fix observed behavior in FINDING F1. |
| E4 | `benchmark/PROBLEM.md` | "return (exc_value.__cause__ or (None if exc_value.__suppress_context__ else exc_value.__context__))" | Cause resolution prioritizes explicit cause, otherwise suppresses or exposes context based on `__suppress_context__`. | Encoded in PO1. |
| E5 | `repo/django/views/templates/technical_500.html` and `.txt` | Template branches on `frame.exc_cause_explicit`. | The frame key is a branch flag, so it should be a boolean explicit-cause predicate. | Encoded in PO3 and FINDING F2. |
| E6 | `repo/django/views/debug.py` | `get_traceback_frames()` builds an `exceptions` chain before rendering frames. | The traversal loop must use the same cause resolver that satisfies E1-E4. | Encoded in PO2. |
