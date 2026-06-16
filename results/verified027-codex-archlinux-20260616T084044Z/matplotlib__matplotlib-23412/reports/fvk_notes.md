# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found that the V1 edit is exactly the source
change required by the public intent: remove the draw-time override that forced
patch dash offsets to zero.

## Trace to findings and proof obligations

1. Kept the V1 source change in `repo/lib/matplotlib/patches.py`.

   Justification: F-001 identifies the pre-fix code bug as `Patch.draw()`
   replacing `_dash_pattern[0]` with `0`. PO-4 requires `Patch.draw()` to enter
   `_bind_draw_path_function()` without replacing the stored offset. V1 satisfies
   PO-4 by removing the temporary `_dash_pattern=(0, ...)` override.

2. Made no further changes to `Patch.set_linestyle` or `Patch.set_linewidth`.

   Justification: F-002 and PO-3 show that the setter/scaling path already
   preserves tuple offsets: `_get_dash_pattern` normalizes the offset and
   `_scale_dashes` scales it with linewidth. The defect was not in parsing or
   scaling.

3. Made no backend changes.

   Justification: PO-2 requires the model to preserve the property under audit,
   and it distinguishes the failing pre-fix offset `0` from the V1 forwarded
   offset. F-005 records backend pixel rendering as a residual trusted component,
   not a source-code bug surfaced by this issue. The public source evidence
   localizes the defect before the backend boundary.

4. Added no warning or compatibility shim.

   Justification: F-003 records the only compatibility change: users who passed
   non-zero offsets but relied on them being ignored will now see the offset
   honored. PO-6 requires public compatibility review, and the public issue
   discussion rejects preserving that legacy behavior.

5. Did not modify tests or add a release note.

   Justification: F-004 records future test and release-note work, while this
   benchmark phase forbids modifying test files and asks for source repair plus
   reports. PO-7 also prevents recommending test removal without a future
   machine check.

6. Added FVK artifacts under `fvk/`.

   Justification: PO-1 through PO-7 require intent provenance, a
   property-complete formal model, draw-forwarding proof obligations, frame
   conditions, and the honesty gate. The artifacts include the required five
   benchmark files plus the FVK adequacy core and `.k` files required by the
   FVK documentation.

## Commands intentionally not run

Per the benchmark instructions, I did not run tests, Python, `kompile`, `kast`,
or `kprove`. `fvk/PROOF.md` records the K commands that should be run later in
an environment with the K framework installed.
