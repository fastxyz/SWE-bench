# Formal Spec English

This file paraphrases the nontrivial K claims and side conditions.

## Claim C1: Sliced Inverse Correctness

Given a valid sliced WCS, a kept-pixel vector `p`, and a wrapped WCS that is
invertible for the full pixel vector made from `p` and the fixed slice pixels:
if the caller passes the kept world components obtained from that full pixel
vector, `SlicedLowLevelWCS.world_to_pixel_values` returns exactly `p`.

The claim includes the side condition that dropped world axes are independent of
kept pixel axes according to `axis_correlation_matrix`, so the dropped world
coordinate at sliced pixel zero is the correct omitted coordinate for all kept
pixel values in the slice.

## Claim C2: Fixed Dropped World Values

The helper for dropped world values evaluates the wrapped WCS at the full pixel
vector formed by inserting the fixed integer slice pixels and using zero for
kept sliced coordinates. These values are used for dropped world axes when
reconstructing the full world vector for the wrapped inverse transform.

## Claim C3: Metadata Consistency

The dropped-world metadata uses the same fixed dropped world vector as the
inverse transform. A caller reading `dropped_world_dimensions["value"]` sees the
world coordinate associated with the fixed pixel slice, not an unrelated
placeholder.

## Frame Conditions

The proof does not change public call signatures, the order of input world
components, the order of returned pixel components, range-slice start handling,
or public metadata keys.

## Machine-Check Status

The proof is constructed but not machine-checked. The emitted commands in
`fvk/PROOF.md` describe how to run `kompile`, `kast`, and `kprove` later.
