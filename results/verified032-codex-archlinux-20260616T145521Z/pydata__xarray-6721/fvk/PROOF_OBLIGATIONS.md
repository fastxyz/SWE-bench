# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-001: `Variable.chunks` is a no-load metadata accessor

Source: `repo/xarray/core/variable.py`.

Precondition: `self` is a `Variable` with internal `_data`.

Claim: `self.chunks` returns `getattr(self._data, "chunks", None)` and does not call `self.data`, `self.values`, `np.asarray`, `__array__`, or backend indexing.

Why it matters: this is the primitive metadata read used by V1. If this loaded data, V1 would not address F-001.

Status: discharged by source inspection and represented by K claim 1 in `fvk/xarray-chunks-spec.k`.

## PO-002: `Variable.chunksizes` is a no-load mapping constructor

Source: `repo/xarray/core/variable.py`.

Precondition: `self.chunks` satisfies PO-001.

Claim: if `self.chunks is None`, `self.chunksizes` returns `{}`. Otherwise, it returns `Frozen({dim: c for dim, c in zip(self.dims, chunks)})`. It does not access `self.data`.

Why it matters: `get_chunksizes()` delegates to `v.chunksizes` for chunked variables, so this must not reintroduce the materializing path from F-001.

Status: discharged by source inspection and represented by K claims 2-3 in `fvk/xarray-chunks-spec.k`.

## PO-003: `get_chunksizes()` aggregates chunks without materialization

Source: `repo/xarray/core/common.py`.

Precondition: `variables` is a finite iterable of `Variable` instances whose `chunks` and `chunksizes` satisfy PO-001 and PO-002.

Loop invariant: after processing any prefix of `variables`, the local `chunks` dict contains exactly the merged dimension-to-chunks entries contributed by chunked variables in that prefix, unless a conflicting entry has already raised `ValueError`. No processed step has called a materializing API.

Postcondition: on a consistent input, the function returns `Frozen(chunks)` for the full iterable. On a conflicting input, it raises the existing `ValueError` before overwriting the prior dimension entry. It never calls `v.data`.

Status: discharged by source inspection and represented by K claim 4 in `fvk/xarray-chunks-spec.k`.

## PO-004: Public callers inherit the no-load property

Sources: `repo/xarray/core/dataset.py` and `repo/xarray/core/dataarray.py`.

Claim: `Dataset.chunks`, `Dataset.chunksizes`, and `DataArray.chunksizes` delegate to `get_chunksizes()`, so PO-003 covers the reported `ds.chunks` symptom and the sibling chunk-size accessor.

Status: discharged by source inspection.

## PO-005: Return semantics and error behavior are preserved

Claim: V1 changes the metadata access path only. It does not change function signatures, public caller signatures, the inconsistent-chunks error text, or the mapping calculation for dask-chunked variables.

Status: discharged by source inspection and compatibility audit in `fvk/SPEC.md`.

## PO-006: Adequacy of the spec against public intent

Claim: the formal claims cover the public issue's root cause and do not prove a weaker or legacy-derived contract.

Status: discharged by the adequacy audit in `fvk/SPEC.md`. The only ambiguous wording is the issue's reference to `encoding`; F-002 records why this is not a source-change obligation.
