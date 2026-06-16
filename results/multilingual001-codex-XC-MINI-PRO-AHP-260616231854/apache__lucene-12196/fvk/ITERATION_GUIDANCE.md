# Iteration Guidance

Status: V1 stands unchanged after FVK audit.

## Decision

No additional source edit is justified. Findings F-001 and F-002 are resolved by V1, and F-003
confirms the current implementation satisfies proof obligations PO-001 through PO-008. F-004 remains
only the required honesty caveat that the proof has not been machine-checked.

## Recommended Follow-up Tests For A Normal Development Environment

Do not modify tests in this benchmark. In a normal Lucene development pass, add or keep coverage for:

- `MultiFieldQueryParser` with one boosted field parsing `"hello world"~1`, asserting the resulting
  inner `PhraseQuery` has slop `1` and the wrapping `BoostQuery` has boost `1.5`.
- A boosted multi-phrase/synonym phrase case, asserting the `MultiPhraseQuery` slop is preserved under
  `BoostQuery`.
- A no-boost phrase case, asserting existing slop behavior remains unchanged.
- A non-phrase boosted query case, asserting field boosts remain preserved without phrase slop
  transformation.

## Commands For Later Machine Checking

These commands are emitted for a future environment with K installed. They were not run here.

```sh
kompile fvk/mini-queryparser.k --backend haskell
kast --backend haskell fvk/multifield-queryparser-spec.k
kprove fvk/multifield-queryparser-spec.k
```

Keep all tests until the proof is machine-checked and the project test suite passes in a real
execution environment.

## Next Code Generation Prompt If V1 Were Regenerated

Use this instruction:

"In `MultiFieldQueryParser.applySlop`, treat `BoostQuery` as a transparent wrapper for phrase slop:
unwrap it, recursively apply the existing slop logic to the wrapped query, then rewrap the result
with the same boost. Preserve existing direct `PhraseQuery`, `MultiPhraseQuery`, null, and non-phrase
behavior. Do not change public APIs or tests."
