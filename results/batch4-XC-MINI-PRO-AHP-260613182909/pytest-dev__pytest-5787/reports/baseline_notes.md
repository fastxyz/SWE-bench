# Baseline notes — pytest-dev__pytest-5787

## Issue

When a test fails with a *chained* exception (either `raise ... from ...` or an
exception raised while handling another), pytest normally prints the whole chain
("The above exception was the direct cause of the following exception:" /
"During handling of the above exception, another exception occurred:").

However, when the tests are distributed with `pytest-xdist` (`-n auto`), only the
**last** exception in the chain is shown. The hint states the root problem
plainly: *"currently exception serialization is best described as limited and
simplistic"*.

## Root cause

xdist runs tests in worker subprocesses and ships each `TestReport` back to the
master process. The (de)serialization lives in
`src/_pytest/reports.py` — `BaseReport._to_json()` /
`BaseReport._from_json()` (exposed through the
`pytest_report_to_serializable` / `pytest_report_from_serializable` hooks).

For a failing test the report's `longrepr` is normally an
`ExceptionChainRepr` (`src/_pytest/_code/code.py`). That object holds:

* `reprtraceback` / `reprcrash` — the *outermost* exception only, and
* `chain` — a list of `(reprtraceback, reprcrash, description)` tuples, **one per
  exception in the chain**. Its `toterminal()` walks `chain` to render every link.

The old `_to_json()` serialized **only** `reprtraceback` and `reprcrash` (the
outermost exception) plus `sections`; it never serialized `chain`. On the master
side `_from_json()` rebuilt a single-exception `ReprExceptionInfo`. So every link
except the last was silently dropped — exactly the reported symptom.

## Fix

`src/_pytest/reports.py` only (plus one import).

### `_to_json()`
Replaced the inline `disassembled_report()` helper with small, composable
serializers — `serialize_repr_entry`, `serialize_repr_traceback`,
`serialize_repr_crash`, and `serialize_longrepr`. `serialize_longrepr` still emits
the top-level `reprcrash`/`reprtraceback`/`sections` (preserving the existing wire
layout and the detection done by `_from_json`), and now **additionally** emits a
`"chain"` key:

* when `longrepr` is an `ExceptionChainRepr`, `chain` is the list of
  `(serialized reprtraceback, serialized reprcrash | None, description)` tuples;
* otherwise (e.g. `--tb=native`, which yields a `ReprExceptionInfo`), `chain` is
  `None`.

`serialize_repr_crash` tolerates `None`, because a chain link for an exception
without a traceback carries `reprcrash is None` (see `repr_excinfo`).

### `_from_json()`
Refactored the inline entry loop into `deserialize_repr_entry`,
`deserialize_repr_traceback`, and `deserialize_repr_crash`. The outermost
`reprtraceback`/`reprcrash` are still deserialized first — this keeps the existing
"unknown entry type" validation working on the top-level traceback and provides
the object used for the non-chain branch. Then:

* if `longrepr["chain"]` is present, every link is deserialized and an
  `ExceptionChainRepr` is rebuilt, so `toterminal()` renders the full chain again;
* otherwise a `ReprExceptionInfo` is rebuilt exactly as before.

### Import
Added `from _pytest._code.code import ExceptionChainRepr`.

## Why the round-trip is faithful

`ExceptionChainRepr.__init__` sets `reprtraceback`/`reprcrash` from `chain[-1]`,
so the reconstructed object exposes the same `.reprtraceback`/`.reprcrash`
attributes the existing serialization tests assert on, while `.chain` now drives
the full multi-exception terminal output.

## Assumptions / alternatives considered

* **Keep the top-level `reprtraceback`/`reprcrash` even though they duplicate
  `chain[-1]`.** Kept on purpose: `_from_json` recognizes this report layout via
  `"reprcrash" in longrepr and "reprtraceback" in longrepr`, and the existing test
  `test_xdist_longrepr_to_str_issue_241` reads
  `_to_json()["longrepr"]["reprtraceback"]["style"]`. Dropping them would break
  detection and that contract.
* **Deserialize the top-level traceback unconditionally** (before the chain/no-chain
  branch). This is the slightly redundant-looking line in the chain branch, but it
  is deliberate: it preserves the malformed-report detection that
  `test_unserialization_failure` exercises against the top-level traceback, and it
  supplies the object the non-chain branch needs. The chain links are independent
  serialized copies, so this never aliases or double-counts data.
* **Serialize the chain only and drop the redundant top-level fields.** Rejected: it
  would break the layout-detection check and the existing test contract above.
* **Fix it in `ExceptionChainRepr` / `_code/code.py` instead.** Rejected: the data
  is produced correctly there already; the loss happens purely in xdist's
  report (de)serialization, so `reports.py` is the correct and minimal place.
* **Native tracebacks (`--tb=native`).** These produce `ReprExceptionInfo`, not
  `ExceptionChainRepr`; `chain` is serialized as `None` and the original
  single-traceback path is taken, so behavior is unchanged for that style.
* **Wire format (tuples vs lists).** Deserialization unpacks each chain element
  with `for a, b, c in chain`, which works whether the transport (execnet or a
  JSON round-trip) preserves tuples or turns them into lists.
