# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, tests,
Python, or project code were executed.

## Claims

The K artifacts are:

- `fvk/mini-sliced-wcs.k`
- `fvk/sliced-wcs-spec.k`

They model only the sliced-wrapper coordinate reconstruction logic. The wrapped
WCS transforms are abstract functions `p2w` and `w2p`.

## Claim C1: Sliced Inverse Correctness

Preconditions:

- `validSlicedWCS(W, S, PK, WK)`;
- dropped worlds are independent of kept pixels under the correlation matrix;
- the wrapped WCS inverse holds on the full pixel vector for this slice;
- slice-start adjustment and kept-pixel projection are well formed.

Goal:

```
worldToPixelValues(W, S, PK, WK,
  selectKeptWorlds(p2w(W, expandPixels(S, P)), WK))
=> P
```

## Proof Sketch

1. Symbolically execute the `worldToPixelValues` rule from
   `mini-sliced-wcs.k`.

2. The rule rewrites the call to:

   ```
   selectKeptPixels(
     adjustForSliceStarts(
       w2p(W, mergeKeptAndDroppedWorlds(WK, WIN,
         p2w(W, expandPixelsAtSlicedZero(S)))),
       S),
     PK)
   ```

3. Substitute the claim input:

   ```
   WIN = selectKeptWorlds(p2w(W, expandPixels(S, P)), WK)
   ```

4. By O3, the merge of caller-provided kept world components and fixed dropped
   world components equals the full world vector:

   ```
   p2w(W, expandPixels(S, P))
   ```

5. By O4, the wrapped inverse reduces:

   ```
   w2p(W, p2w(W, expandPixels(S, P))) == expandPixels(S, P)
   ```

6. By O5, slice-start adjustment and kept-pixel projection reduce:

   ```
   selectKeptPixels(adjustForSliceStarts(expandPixels(S, P), S), PK) == P
   ```

7. By transitivity, the original call reaches `P`.

There are no recursive calls and no unbounded loops in the audited wrapper path,
so no circularity claim is needed.

## Claim C2: Dropped World Values

Goal:

```
droppedWorldValues(W, S) => p2w(W, expandPixelsAtSlicedZero(S))
```

Proof: one symbolic rewrite by the `droppedWorldValues` rule in
`mini-sliced-wcs.k`.

## Proof-Derived Findings

- F1 is the original code bug: `1.0` cannot satisfy O2 unless it accidentally
  equals the fixed dropped world value.
- F2 is the V1 audit finding: caching the fixed-world vector in the transform
  path is not required by any obligation and weakens compatibility with live
  wrapped-WCS delegation.
- F3 is a proof capability boundary: the proof assumes, rather than proves, the
  wrapped WCS inverse and NumPy/FITS behavior.

## Test Redundancy Recommendation

No tests were removed or edited. If the abstract K proof is later
machine-checked, focused unit tests that assert only the abstract reconstruction
identity may be redundant. FITS/WCS integration tests, broadcasting tests, and
the issue regression should still be kept because F3 leaves wrapped-WCS and
NumPy behavior outside this proof.

## Reproduce The Machine Check Later

Run from the repository root:

```sh
kompile fvk/mini-sliced-wcs.k --backend haskell
kast --backend haskell fvk/sliced-wcs-spec.k
kprove fvk/sliced-wcs-spec.k
```

Expected outcome: `#Top` for the abstract claims. Until then, this remains
constructed, not machine-checked.
