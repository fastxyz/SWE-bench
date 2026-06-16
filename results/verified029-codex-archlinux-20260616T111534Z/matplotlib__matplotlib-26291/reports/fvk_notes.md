# FVK Notes

## Decision Summary

V1 stands unchanged. The FVK audit found that the existing two-line fallback in
`repo/lib/mpl_toolkits/axes_grid1/inset_locator.py` satisfies the public intent
and the proof obligations for the reported failure.

## Decisions Traced to FVK Artifacts

- Kept the V1 `renderer is None` fallback in `AnchoredLocatorBase.__call__`.
  - Justification: F-001 identifies the pre-V1 failure as forwarding
    `renderer=None` into `OffsetBox.get_window_extent`; PO-002 requires
    resolving the renderer from `ax.figure._get_renderer()`.
  - Result: no additional code change needed.

- Confirmed that the fallback is placed correctly before
  `get_window_extent` and `get_offset`.
  - Justification: F-002 shows both extent/size and offset calculations need a
    non-`None` renderer; PO-004 requires all renderer consumers to receive the
    effective renderer.
  - Result: V1 covers the second-order failure that would remain if only
    `self.figure` were set.

- Kept provided-renderer behavior unchanged.
  - Justification: F-003 confirms no public API or dispatch compatibility
    problem; PO-003 requires the explicit-renderer path to preserve existing
    behavior.
  - Result: no refactor or signature change was made.

- Rejected setting `axes_locator.figure` in `_add_inset_axes`.
  - Justification: F-001 and F-002 localize the bug to missing effective
    renderer plumbing in `__call__`; PO-005 says the successful path should not
    depend on the locator's own `figure`.
  - Result: no state-plumbing edit was made.

- Rejected changing `_tight_bbox.adjust_bbox`.
  - Justification: `fvk/SPEC.md` evidence E-006 establishes `locator(ax, None)`
    as the caller behavior to support, and PO-002 localizes the required
    behavior to this locator's fallback.
  - Result: the fix remains scoped to `axes_grid1/inset_locator.py`.

- Rejected adding broad validation for invalid axes objects.
  - Justification: F-004 confirms V1 for in-domain locator calls, while PO-007
    limits the domain to real Matplotlib axes with figures.
  - Result: no unrelated guard or error-policy change was made.

- Did not run tests, Python code, or K tooling, and did not modify tests.
  - Justification: F-005 and PO-008 record the benchmark prohibition and the
    FVK honesty gate.
  - Result: proof artifacts are labeled constructed, not machine-checked, and
    all test guidance is recommendation-only.

## Artifacts Produced

Required FVK artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Additional adequacy and formal-core artifacts required by the FVK method docs:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-python.k`
- `fvk/inset-locator-spec.k`
