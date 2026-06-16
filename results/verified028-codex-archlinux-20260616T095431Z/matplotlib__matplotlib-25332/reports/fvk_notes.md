# FVK notes

The FVK audit confirms V1 should stand unchanged.

`fvk/FINDINGS.md` F1 traces the public failure to raw `weakref.ref` objects inside `cbook.Grouper._mapping`. `fvk/PROOF_OBLIGATIONS.md` O1 is satisfied by V1's `Grouper.__getstate__()` returning `list(self)`, which exposes live grouped objects rather than the weakref-backed mapping. This directly addresses the reported `TypeError: cannot pickle 'weakref.ReferenceType' object`.

`fvk/FINDINGS.md` F2 records why a narrower fix that simply removed `_align_label_groups` from figure pickle state was rejected: the alignment docstrings promise persistence for later draw events. `fvk/PROOF_OBLIGATIONS.md` O2 and O3 are satisfied by V1's `Grouper.__setstate__()` loop, which rebuilds a fresh weakref mapping by joining every serialized group.

`fvk/FINDINGS.md` F3 and F4 identify two caveats that do not justify code changes for this issue. A standalone unpickled `Grouper` needs external strong references to keep members alive, but aligned figures already hold Axes elsewhere in the figure graph. Malformed manual `__setstate__()` inputs are outside the pickle path produced by `__getstate__()`.

`fvk/PROOF_OBLIGATIONS.md` O5 confirms V1 does not alter existing `Grouper` public methods or signatures. Therefore no source file was edited during the FVK pass. The proof artifacts are constructed, not machine-checked, and the emitted K commands in `fvk/PROOF.md` were intentionally not run.
