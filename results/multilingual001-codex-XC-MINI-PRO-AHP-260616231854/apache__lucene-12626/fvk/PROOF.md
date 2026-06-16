# FVK Proof

Status: constructed, not machine-checked.

## Theorem

For every non-null replacement `SegmentInfos other`, `SegmentInfos.replace(other)` produces a
receiver whose segment list, `lastGeneration`, and `userData` come from `other`, while preserving
the receiver's `generation`, `version`, and `counter`.

## Formal Claim

The formal claim is in `fvk/segmentinfos-replace-spec.k` over the mini semantics in
`fvk/mini-java-segmentinfos.k`.

Object abstraction:

```text
si(segments, lastGeneration, userData, generation, version, counter)
```

Claim:

```text
replace(si(S0, L0, U0, G0, V0, C0), si(S1, L1, U1, G1, V1, C1))
=> si(S1, L1, U1, G0, V0, C0)
```

## Constructed Proof Sketch

1. Initial symbolic state:

   ```text
   this  = si(S0, L0, U0, G0, V0, C0)
   other = si(S1, L1, U1, G1, V1, C1)
   ```

2. Execute `rollbackSegmentInfos(other.asList())`.

   The modeled effect of `rollbackSegmentInfos` is to clear the receiver segment list and add all
   entries from `other.asList()`. Therefore:

   ```text
   segments = S1
   lastGeneration = L0
   userData = U0
   generation = G0
   version = V0
   counter = C0
   ```

3. Execute `lastGeneration = other.lastGeneration`.

   ```text
   segments = S1
   lastGeneration = L1
   userData = U0
   generation = G0
   version = V0
   counter = C0
   ```

4. Execute V1 assignment `userData = other.userData`.

   ```text
   segments = S1
   lastGeneration = L1
   userData = U1
   generation = G0
   version = V0
   counter = C0
   ```

5. The final state is exactly the post-state of the claim:

   ```text
   si(S1, L1, U1, G0, V0, C0)
   ```

6. Frame conditions hold because V1 does not write `generation`, `version`, or `counter`.

## Why Pre-V1 Fails

Without step 4, the final state would be:

```text
si(S1, L1, U0, G0, V0, C0)
```

When `U0 != U1`, that state contradicts PO-3 and the issue intent.

## Loop and Termination Notes

`replace` has no loop or recursion. The proof is a straight-line partial-correctness proof. There
is no termination obligation beyond the called list operations returning normally on the stated
domain.

## Test Guidance

No tests are recommended for removal. The proof was constructed but not machine-checked, the
benchmark forbids running tests, and the fixed test suite is hidden. A useful public regression test
would create two commits with different live commit data, open or initialize through an explicit
older commit path, and assert that the resulting commit data is the older commit's data.

## Exact Commands To Machine-Check Later

These commands are recorded only; they were not run.

```sh
kompile fvk/mini-java-segmentinfos.k --backend haskell
kast --backend haskell fvk/segmentinfos-replace-spec.k
kprove fvk/segmentinfos-replace-spec.k
```

Expected result after a real machine check: `kprove` discharges the claim to `#Top`.
