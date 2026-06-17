# ITERATION_GUIDANCE.md

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged.

The FVK audit found the original bug in the same place as the baseline notes:
the direction of the final prefix restoration loop. The V1 change satisfies the
intent-derived ordering contract and the constructed proof obligations.

## Traceability

- Keep V1 unchanged because F-002 discharges PO-3 and PO-4.
- Do not broaden the source patch because F-003 frames the rest of the Kahane
  graph algorithm as unchanged context, and PO-5 confirms the diff does not
  alter it.
- Do not edit tests because the benchmark forbids test-file changes and PO-8
  keeps all proof/test-removal claims behind the honesty gate.

## Suggested Follow-up Outside This Benchmark

1. Machine-check the emitted K artifacts:

   ```sh
   kompile fvk/mini-kahane-prefix.k --backend haskell
   kast --backend haskell fvk/kahane-prefix-spec.k
   kprove fvk/kahane-prefix-spec.k
   ```

2. Add a public regression test equivalent to the issue witness:

   ```text
   kahane_simplify(G(rho)*G(sigma)*G(mu)*G(-mu))
   == 4*G(rho)*G(sigma)
   ```

3. Keep broader tensor integration tests because the mini-model only proves the
   prefix ordering slice.
