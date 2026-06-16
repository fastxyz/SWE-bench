# FVK Specification: pytest-dev__pytest-5787

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The audited units are the report longrepr serialization helpers and their use
from `BaseReport._to_json` and `BaseReport._from_json` in
`repo/src/_pytest/reports.py`.

The observable being specified is the failure report longrepr that a controller
process receives after xdist-style serialization/deserialization. The relevant
properties are structural preservation of traceback entries, crash locations,
sections, and exception-chain ordering/descriptions, plus compatibility with the
existing single-exception report shape.

## Intent-Only Spec

I-001: A serialized report for a chained exception must contain enough
information for the receiving process to render every exception in the chain.
This includes direct-cause chains produced by `raise ... from ...` and implicit
context chains produced while handling another exception.

I-002: The rendered chain order must match local pytest output: oldest exception
first, then the chain description, ending with the newest exception.

I-003: The chain description text is semantically significant. Direct causes
must preserve "The above exception was the direct cause of the following
exception:"; implicit contexts must preserve "During handling of the above
exception, another exception occurred:".

I-004: Existing structured report fields used by pytest and plugins must remain
available: top-level `reprtraceback`, top-level `reprcrash`, traceback entry
details, and sections.

I-005: The fix should not change non-chained report behavior beyond what is
needed to support actual chains. In particular, ordinary single-exception
failure reports should keep the previous serialized/deserialized shape.

## Public Evidence Ledger

E-001, prompt: "exception serialization should include chained exceptions".
Obligation: encode and decode the full exception chain, not only the newest
exception. Status: encoded by PO-004 and PO-005.

E-002, prompt: "when run without xdist it displays whole exception trace nicely"
followed by the full direct-cause and context examples. Obligation: the
serialized/deserialized report should be able to render the same complete chain
as local reporting. Status: encoded by PO-005.

E-003, prompt: "but when run with xdist (`-n auto`), it just displays the last
one" followed by output containing only `ValueError: 13` and `ValueError: 23`.
Obligation: this last-exception-only behavior is SUSPECT legacy behavior, not a
specification to preserve. Status: recorded as finding F-001.

E-004, public hint: "currently exception serialization is best described as
limited and simplicistic". Obligation: the defect is in the serialization layer,
so the fix should target report serialization rather than exception formatting
itself. Status: encoded by PO-004 and PO-005.

E-005, source code `ExceptionChainRepr.__init__`: `reprtraceback` and
`reprcrash` are the outermost exception's fields; `chain` carries all chain
elements. Obligation: serializing only top-level `reprtraceback`/`reprcrash`
cannot preserve earlier chain elements. Status: recorded as finding F-001.

E-006, source code `ExceptionChainRepr.toterminal`: each chain element is
rendered in order and its description is printed after that element when
present. Obligation: chain serialization must preserve element order and
description. Status: encoded by PO-004 and PO-005.

E-007, public tests in `repo/testing/test_reports.py`: existing report
serialization checks top-level `reprtraceback`, `reprcrash`, entries, and
sections. Obligation: retain those fields and entry fidelity. Status: encoded
by PO-001, PO-002, PO-003, and PO-006.

E-008, compatibility audit of V1: `ExceptionInfo.getrepr()` returns
`ExceptionChainRepr` even for a single exception. Obligation: adding a `chain`
field for every `ExceptionChainRepr` would alter ordinary single-exception
round trips. Status: recorded as finding F-002 and fixed by PO-006.

## Formal Model

The K artifacts use an abstract mini model of pytest report longreprs:

- `Entry` represents either `ReprEntry` or `ReprEntryNative` together with its
  data map.
- `Traceback` represents ordered `reprentries`, `extraline`, and `style`.
- `Crash` represents `ReprFileLocation` or `None`.
- `Longrepr` is either a single `ReprExceptionInfo`-style representation or an
  `ExceptionChainRepr` with an ordered list of chain elements and sections.
- `JsonLongrepr` is the serialized dictionary shape with top-level traceback,
  crash, sections, and an optional `chain` field.

This abstraction is property-complete for the issue because it distinguishes a
passing chained report from the failing legacy report: the failing report has no
serialized `chain` field and therefore cannot reconstruct earlier chain
elements or descriptions.

Formal files:

- `fvk/mini-pytest-report.k`
- `fvk/report-serialization-spec.k`

## Adequacy Audit

A-001 passes: The formal claims require multi-element chains to round-trip as
chains with the same ordered elements and descriptions. This matches I-001,
I-002, and I-003.

A-002 passes: The formal claims keep top-level traceback/crash fields in the
serialized dictionary and preserve entry data, matching I-004.

A-003 passes after V2: The formal claims omit the optional `chain` field for
single-element chain objects and deserialize through the single-exception shape,
matching I-005. V1 failed this compatibility point.

A-004 passes: The spec does not preserve the issue's xdist "last one only"
output. That output is marked SUSPECT by E-003 because it is the reported bug.

## Public Compatibility Audit

C-001: No public method signatures were changed. `_to_json` and `_from_json`
keep the same call signatures.

C-002: The serialized dictionary still includes top-level `reprtraceback`,
`reprcrash`, and `sections` for structured longreprs.

C-003: The new `chain` key is additive and appears only for actual
multi-exception chains after V2. Older consumers that only inspect top-level
fields can still do so.

C-004: Unknown serialized entry types still route to
`_report_unserialization_failure`.

C-005: Non-structured longreprs, passed reports with `longrepr is None`, path
normalization, and `result` clearing remain outside the changed behavior.
