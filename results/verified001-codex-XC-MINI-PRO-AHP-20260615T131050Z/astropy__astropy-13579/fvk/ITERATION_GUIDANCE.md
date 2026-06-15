# Iteration Guidance

Status: V2 source is the recommended repair from this FVK pass.

## Code Decision

Keep the V1 semantic correction: dropped world axes in `world_to_pixel_values`
must use the fixed-slice world values, not `1.0`.

Improve V1 by removing the lazy cache from the transform helper. The helper is
now a regular method, computed per inverse call when a dropped world axis is
present. This discharges F2/O7 without changing public APIs.

## Do Not Change

- Do not modify tests in this benchmark task.
- Do not change public method signatures or return shapes.
- Do not replace the wrapped WCS inverse or correlation-matrix logic; those are
  outside the narrow bug fix and are modeled as proof assumptions.

## Recommended Future Work Outside This Task

- Add a regression test for the issue's coupled celestial/spectral WCS case.
- Add a broadcasted-array variant of the same regression.
- Keep FITS/WCS integration tests even if the abstract K proof is
  machine-checked, because F3 leaves wrapped-WCS numerical behavior outside the
  proof.
- If stronger proof is required, replace the abstract `p2w`/`w2p` functions with
  a richer model of the relevant WCS linear transform and NumPy broadcasting.
