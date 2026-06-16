# FVK Notes

## Summary

The FVK audit confirms the V1 source change:

```python
for curve, code in p.iter_bezier(simplify=False):
```

No additional production-code edit is justified by the constructed
specification, findings, or proof obligations.

## Decisions

1. Keep V1 unchanged.

   - Trace: F-001 identifies the pre-V1 bug as default path simplification
     under-approximating long step polygon vertices.
   - Trace: PO-2 shows `simplify=False` is the needed iterator condition to
     prevent that loss.
   - Trace: PO-3 shows the existing endpoint and Bezier-extrema collection
     remains intact.
   - Trace: PO-4 shows the reported histogram density maximum is an original
     step-polygon vertex, so the V1 iterator change is sufficient to include
     it in `update_datalim`.

2. Do not add a histogram-specific manual `dataLim` update.

   - Trace: F-003 and PO-4 show the generic patch limit path now covers the
     step histogram observable, including horizontal orientation after x/y
     swapping.
   - Trace: PO-5 favors the narrower fix because it preserves existing patch
     update flow and public behavior.

3. Do not change `Path.iter_bezier` or `Path.iter_segments` defaults.

   - Trace: F-001 localizes the defect to using a simplifiable iterator for
     data-limit computation, not to path simplification as a rendering feature.
   - Trace: F-005 and PO-5 show the compatibility-preserving edit is the
     internal `_update_patch_limits` callsite.

4. Preserve the existing Bezier-extrema logic.

   - Trace: F-002 records that V1 still calls `axis_aligned_extrema()` and
     appends `curve([0, *dzeros, 1])`.
   - Trace: PO-3 requires endpoints and Bezier extrema to remain part of the
     candidate point set.

5. Keep the proof boundary explicit.

   - Trace: F-004 and PO-6 state that the mini semantics abstracts NumPy,
     transforms, `Bbox`, and full Matplotlib behavior.
   - Result: the proof supports the reported step-histogram issue, but does
     not justify removing broad integration tests or claiming full-library
     verification.

6. Do not run tests or K tooling.

   - Trace: F-006 and PO-7 record the benchmark no-execution rule.
   - Result: commands are written into the artifacts, but nothing was
     executed and no test files were modified.

## Artifact Changes

Created the required FVK artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Also added the formal core files referenced by the FVK documentation:

- `fvk/mini-python.k`
- `fvk/patch-limits-spec.k`

All FVK proof material is labeled constructed, not machine-checked.
