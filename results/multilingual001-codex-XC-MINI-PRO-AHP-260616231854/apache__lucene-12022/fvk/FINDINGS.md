# FVK Findings

Status: static FVK findings, constructed but not machine-checked.

## F-1: V1 addresses the reported collapsed-first-edge bug

- Classification: confirmed fix.
- Evidence: `PROBLEM.md` says a flattened triangle line must take polygon-edge knowledge from a segment "not being collapsed"; `LatLonShapeQuery` and `XYShapeQuery` pass only `scratchTriangle.ab` to `withinLine`.
- Symbolic input: `A == B`, `C` distinct, old `ab = false`, old `bc = true`.
- Pre-V1 observed behavior: after line canonicalization, `ab` stayed `false`, so `withinLine` treated the retained line as not from the polygon boundary.
- Expected behavior: after line canonicalization, `ab` is `true`, because the retained segment is old `B-C`.
- V1 behavior: `triangle.ab = triangle.bc` before rewriting `B = C`, so `withinLine` receives `true`.
- Proof obligation: PO-1, PO-4.

## F-2: Other line-degenerate branches do not need the V1 metadata move

- Classification: no additional source change required.
- Evidence: In the `A == C` and `B == C` line cases, the canonical represented line observed by `withinLine` is `A-B`, and `ab` already corresponds to that non-collapsed segment.
- Symbolic input: `A == C`, `A != B`, any old `ab`; or `B == C`, `A != B`, `A != C`, any old `ab`.
- Observed V1 behavior: `ab` remains old `ab`.
- Expected behavior: `ab` remains the edge flag for represented line `A-B`.
- Proof obligation: PO-2.

## F-3: The proof is constructed only

- Classification: proof process limitation.
- Evidence: The task forbids running K tooling; FVK MVP also requires labeling proofs "constructed, not machine-checked."
- Expected next step outside this environment: run the emitted `kompile` and `kprove` commands and require `#Top` before treating proof-derived test redundancy as machine-confirmed.
- Proof obligation: PO-6.

## Non-findings considered

- Tessellation edge provenance was not changed: `Tessellator.Triangle` already carries a boolean per triangle edge, and the issue-local mismatch occurs when decoded coordinates are rewritten to a line.
- Shape doc-values construction was not changed: shape doc-values geometry queries are not implemented in the inspected source path, while the issue concerns indexed shape geometry search queries.
