# FVK Findings

Status: constructed, not machine-checked. No tests, Python code, or K tooling were run.

## F-001: Pre-V1 chunk metadata access materialized lazy zarr data

Classification: code bug, resolved by V1.

Input: a dataset opened from zarr with `chunks=None`, so variables are lazy backend-backed arrays without dask chunks.

Observed before V1: `Dataset.chunks -> get_chunksizes() -> hasattr(v.data, "chunks")` entered `Variable.data`, then `Variable.values`, then `np.asarray`, eventually reading through `ZarrArrayWrapper.__getitem__`.

Expected: `.chunks` should inspect metadata only and should not read backend array contents.

Evidence: public issue trace in `benchmark/PROBLEM.md`; proof obligations PO-001 through PO-003.

Resolution: V1 replaces the `v.data` predicate in `get_chunksizes()` with `v.chunks`, and replaces `self.data.chunks` in `Variable.chunksizes` with `self.chunks`.

## F-002: Literal "encoding" wording does not justify changing `.chunks` return semantics

Classification: ambiguity resolved by public API compatibility evidence.

Input: an unchunked, lazy zarr-backed variable with zarr storage chunks in `encoding`.

Potential interpretation: return zarr storage chunks from `Dataset.chunks` by reading `encoding["chunks"]` or `encoding["preferred_chunks"]`.

Rejected expected behavior: changing `.chunks` to report zarr storage chunks for arrays that are not dask chunked.

Reason: source docstrings and public tests in this checkout distinguish actual dask chunks from backend-preferred/storage chunks. Tests assert that opening with `chunks=None` leaves variables with `v.chunks is None`, and an unchunked dataset has `data.chunks == {}`.

Resolution: interpret the issue expectation as a metadata-only requirement, not as a return-shape change. V1 stands unchanged.

## F-003: Constructed proof remains un-machine-checked

Classification: proof capability / environment limitation, not a code bug.

Input: the formal claims in `fvk/xarray-chunks-spec.k`.

Observed: the task forbids running K tooling, Python, or tests.

Expected: exact commands are recorded for later machine checking; no test deletion or machine-verified claim is made here.

Resolution: `fvk/PROOF.md` records the commands and labels the proof constructed, not machine-checked.

## F-004: Useful public tests to add later

Classification: test gap.

Suggested tests, not implemented here because test files are fixed:

- A lazy backend-like variable whose `__array__` raises should allow `Dataset.chunks` and `DataArray.chunksizes` to return without touching `__array__`.
- A chunked variable should still contribute the same mapping to `Dataset.chunks`.
- Conflicting chunk tuples along the same dimension should still raise the existing `ValueError`.
