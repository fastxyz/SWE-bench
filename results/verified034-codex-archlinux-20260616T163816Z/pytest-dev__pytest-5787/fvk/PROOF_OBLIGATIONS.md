# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Entry serialization is injective over supported entry types

Claim: For `ReprEntry` and `ReprEntryNative`, serializing an entry and then
deserializing it reconstructs an entry with the same type tag and data fields.

Source coverage: `_serialize_repr_entry`, `_deserialize_repr_entry`.

Finding trace: supports F-001 by preserving traceback details; supports
compatibility evidence E-007.

Status: discharged by construction in `ENTRY-ROUNDTRIP` and
`NATIVE-ENTRY-ROUNDTRIP`.

## PO-002: Traceback serialization preserves ordered entries and metadata

Claim: For every finite traceback entry list, serialization maps entries in the
same order; deserialization reconstructs the same order, `extraline`, and
`style`.

Source coverage: `_serialize_repr_traceback`, `_deserialize_repr_traceback`.

Finding trace: supports F-001 by preserving the text-producing traceback order.

Status: discharged by induction over the entry list in `TRACEBACK-ROUNDTRIP`.

## PO-003: Crash serialization preserves file location data and `None`

Claim: `ReprFileLocation(path, lineno, message)` round-trips through serialized
crash data, and `None` remains `None`.

Source coverage: `_serialize_repr_crash`, `_deserialize_repr_crash`.

Finding trace: supports F-001 and preserves existing report-summary behavior.

Status: discharged by case split in `CRASH-ROUNDTRIP` and
`CRASH-NONE-ROUNDTRIP`.

## PO-004: Multi-exception chain serialization emits all chain elements

Claim: If `longrepr` is an `ExceptionChainRepr` with more than one chain
element, serialized `longrepr` contains a `chain` list with the same length,
same order, same serialized traceback/crash data, and same description for each
element. The top-level `reprtraceback` and `reprcrash` compatibility fields are
still emitted.

Source coverage: `_serialize_exception_longrepr` line with
`len(rep.longrepr.chain) > 1`.

Finding trace: fixes F-001.

Status: discharged by `MULTI-CHAIN-SERIALIZES-CHAIN`.

## PO-005: Multi-exception chain deserialization reconstructs terminal-equivalent chain

Claim: Deserializing a serialized multi-element chain reconstructs an
`ExceptionChainRepr` whose `toterminal` iteration sees the same ordered
tracebacks and descriptions, followed by the same sections.

Source coverage: `_deserialize_exception_longrepr` chain branch.

Finding trace: fixes F-001.

Status: discharged by `MULTI-CHAIN-ROUNDTRIP`.

## PO-006: Single-exception reports keep the previous round-trip shape

Claim: A one-element `ExceptionChainRepr` is serialized without the optional
`chain` field and deserializes through the single-exception `ReprExceptionInfo`
shape, while preserving the same top-level traceback/crash/sections and terminal
output.

Source coverage: `_serialize_exception_longrepr` condition
`len(rep.longrepr.chain) > 1`; `_deserialize_exception_longrepr` no-chain
branch.

Finding trace: fixes F-002.

Status: discharged by `SINGLE-CHAIN-COMPAT`.

## PO-007: Existing non-chain report serialization behavior is framed

Claim: Reports whose `longrepr` has no structured traceback/crash continue to
serialize as strings or raw longreprs as before. Path normalization and `result`
clearing are unchanged.

Source coverage: `BaseReport._to_json`.

Finding trace: supports compatibility audit C-005.

Status: discharged by frame reasoning: V2 only changes the structured
longrepr branch.

## PO-008: Unknown entry types still fail loudly

Claim: An unsupported serialized entry type still calls
`_report_unserialization_failure`.

Source coverage: `_deserialize_repr_entry`.

Finding trace: supports compatibility audit C-004.

Status: discharged by case split on `entry_type`.

## PO-009: Tool and test commands are not executed in this session

Claim: This FVK run is a constructed proof only. The following commands are the
expected machine-check path, not executed here:

```sh
kompile fvk/mini-pytest-report.k --backend haskell
kast --backend haskell fvk/report-serialization-spec.k
kprove fvk/report-serialization-spec.k
```

Finding trace: explains F-003.

Status: open until run outside this no-execution environment.
