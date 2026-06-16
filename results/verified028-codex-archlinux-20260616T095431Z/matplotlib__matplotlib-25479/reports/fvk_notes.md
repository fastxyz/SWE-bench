# FVK Notes

## Decisions

1. Kept and sharpened the V1 registered-name fix.
   - Trace: `fvk/FINDINGS.md` F-01 and F-02.
   - Obligations: `fvk/PROOF_OBLIGATIONS.md` PO-01 and PO-02.
   - Source: `repo/lib/matplotlib/pyplot.py`.
   - Rationale: The public issue requires the registered key supplied to
     `set_cmap("my_cmap_name")` to remain the default key, even when the
     returned `Colormap` object's `.name` differs. V1 fixed the main bug, but
     the FVK proof obligation is identity-based, so the rc assignment now uses
     an explicit `is not None` branch rather than truthiness.

2. Changed `set_cmap(Colormap)` to store the object directly in `image.cmap`.
   - Trace: `fvk/FINDINGS.md` F-03.
   - Obligation: `fvk/PROOF_OBLIGATIONS.md` PO-04.
   - Source: `repo/lib/matplotlib/pyplot.py`.
   - Rationale: The pyplot docstring accepts a `Colormap` instance, and the
     Matplotlib docs and rc validator support object-valued `image.cmap`.
     Storing `cmap.name` for object input preserves the same failure pattern
     whenever the object name is not registered.

3. Updated default lookup helpers to accept object-valued `image.cmap`.
   - Trace: `fvk/FINDINGS.md` F-03.
   - Obligation: `fvk/PROOF_OBLIGATIONS.md` PO-05.
   - Source: `repo/lib/matplotlib/cm.py`.
   - Rationale: Once `image.cmap` may contain a `Colormap` object, both
     `ColormapRegistry.get_cmap(None)` and `_ensure_cmap(None)` must return the
     object directly. `_get_cmap(None)` already had this shape; these changes
     make the default-resolution paths consistent.

4. Preserved invalid-name ordering.
   - Trace: `fvk/FINDINGS.md` F-04.
   - Obligation: `fvk/PROOF_OBLIGATIONS.md` PO-06.
   - Source: `repo/lib/matplotlib/pyplot.py`.
   - Rationale: The call to `get_cmap(cmap)` still happens before `rc(...)`,
     `gci()`, or `im.set_cmap(...)`, so invalid registered-name lookups fail
     before mutating the default or a current image.

## Artifacts

The FVK package is under `fvk/`:

- `SPEC.md`
- `FINDINGS.md`
- `PROOF_OBLIGATIONS.md`
- `PROOF.md`
- `ITERATION_GUIDANCE.md`
- `mini-pyplot-cmap.k`
- `pyplot-set-cmap-spec.k`

The K proof is constructed but not machine-checked. I did not run tests,
Python, `kompile`, `kast`, or `kprove`, per the benchmark instructions.
