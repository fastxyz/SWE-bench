# Formal Spec in English

Status: paraphrase of the K claims in `hexbin-mincnt-spec.k`.

## CLAIM-LOOP

For any finite list of non-negative bin counts and any non-negative threshold
`TH`, the selection loop returns one Boolean per bin. The Boolean for a bin is
`true` exactly when that bin's count is greater than or equal to `TH`.

## CLAIM-COUNT-EXPLICIT

For count-only hexbin mode with explicit positive `mincnt=M`, selected bins are
exactly the bins whose point count is at least `M`.

## CLAIM-C-EXPLICIT

For `C`-aggregation hexbin mode with explicit positive `mincnt=M`, selected bins
are exactly the bins whose point count is at least `M`. Therefore a bin with
exactly one point is selected when `M=1`.

## CLAIM-C-DEFAULT

For `C`-aggregation hexbin mode with `mincnt=None`, selected bins are exactly the
non-empty bins. Empty bins are not passed to the reducer in the default case.

## CLAIM-COUNT-DEFAULT

For count-only hexbin mode with `mincnt=None`, every finite bin is selected,
including bins with count zero.

## Frame Conditions

The claims specify only the selected-bin predicate produced by the min-count
filter. Bin geometry, colormap/norm handling, marginal plotting, public
signatures, and the reducer's numeric result are unchanged frame conditions.
