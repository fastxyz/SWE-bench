# ITERATION GUIDANCE

## Verdict

V1 stands unchanged. The FVK audit found no public-intent or proof-obligation
failure requiring a V2 source edit.

## Why no source edit is justified

- F1 and F2 show that V1 covers the core issue for explicit and inferred nominal
  coordinate scales.
- F3 shows that V1's explicit-limit behavior is the conservative interpretation
  of the public intent and existing `Plot.limit` contract.
- F4 is an ambiguity, not a contradiction: empty nominal axes are not specified.
- F5 is an integration proof boundary around Matplotlib internals; it argues for
  keeping tests, not changing source.

## Recommended future tests

Do not edit tests in this task. Future public tests should cover:

- inferred nominal x axis: no grid and limits `(-.5, n - .5)`;
- inferred nominal y axis: no grid and limits `(n - .5, -.5)`;
- explicit `so.Nominal()` on numeric coordinate values;
- faceted or paired nominal axes using subplot-specific axis keys;
- explicit `Plot.limit(...)` on nominal x and y axes;
- a grid-enabled theme to confirm nominal-axis grid suppression.

## Clarifications worth asking only if future behavior is disputed

- Should a user theme ever be allowed to force a grid on nominal coordinate axes,
  or should nominal always match categorical and suppress it?
- Should empty nominal axes suppress grid, preserve theme grid, or follow another
  explicit empty-axis policy?
- For explicit nominal y limits supplied in reversed order, should seaborn
  preserve that exact order or normalize it to category order before inversion?
