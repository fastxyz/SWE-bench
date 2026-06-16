# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged.

## Why no V2 source edit is needed

F-001 identifies the original defect: a plain merge cannot remove omitted
alterable option keys. PO-002 and PO-003 are the direct proof obligations for
that defect. The V1 source discharges both by merging first and then removing
every `ALTER_OPTION_KEYS` member absent from `operation.options`.

F-003 and PO-004 check the main over-fix risk: deleting too much. V1 avoids that
because the removal loop only visits `ALTER_OPTION_KEYS`.

F-004 and PO-005 check the override risk: deleting a key explicitly supplied by
the `AlterModelOptions` operation. V1 avoids that because it only pops keys not
present in `operation.options`.

PO-006 checks falsey explicit values. V1 uses key presence, not value truthiness,
so explicit falsey values survive.

PO-007 and PO-008 check frame and compatibility obligations. V1 changes no
public signature, branch predicate, or non-option attributes.

## Next steps outside this constrained environment

1. Machine-check the constructed proof after supplying the mini semantics files:

   ```sh
   kompile fvk/mini-migration-options.k --backend haskell
   kast --backend haskell fvk/create-model-reduce-spec.k
   kprove fvk/create-model-reduce-spec.k
   ```

2. Run Django's migration optimizer tests in a normal environment.

3. Add focused tests for the examples listed in `fvk/PROOF.md`.

4. Keep all existing tests until the proof is machine-checked and conventional
   CI passes. Do not delete tests based on this constructed proof alone.

## UltimatePowers-style clarification

No user clarification is needed for this issue. The public prompt and public hint
unambiguously identify `AlterModelOptions.ALTER_OPTION_KEYS` as the key-removal
boundary and `AlterModelOptions.state_forwards()` as the intended behavior to
mirror.
