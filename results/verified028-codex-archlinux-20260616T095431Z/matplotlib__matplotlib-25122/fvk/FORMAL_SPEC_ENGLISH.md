# Formal Spec in English

## Claim PSD-SPECTRUM-SIGNED-SUM

For any symbolic raw PSD bin and any real-window coefficient list whose signed
sum is nonzero, `normalizePsdSpectrum` returns that raw bin scaled by the square
of the signed window sum.

## Claim PSD-SPECTRUM-NEGATIVE-DISCRIMINATOR

For a concrete negative-coefficient window `[3, -1]`, the V1 spectrum
denominator is `4`.

## Claim LEGACY-NEGATIVE-DISCRIMINATOR

For the same window `[3, -1]`, the legacy coefficient-wise absolute denominator
is `16`, demonstrating the reported bug.

## Claim PSD-DENSITY-FRAME

For the density path, `normalizePsdDensity` scales by `Fs` times the squared
coefficient norm. This is the unchanged `scale_by_freq=True` behavior.

## Claim POSITIVE-WINDOW-FRAME

For a positive window `[1, 2]`, V1 and legacy spectrum denominators both equal
`9`.

