# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Public Surface

No public signature changed. The only source edit is the branch grouping inside
private helper `_get_aligned_offsets`.

Observable public behavior changes intentionally for:

- `HPacker(align="bottom")`: now aligns child bottoms.
- `HPacker(align="top")`: now aligns child tops.

Observable public behavior remains unchanged for:

- `HPacker(align="baseline")`
- `HPacker(align="center")`
- `VPacker(align="left")`
- `VPacker(align="right")`
- `VPacker(align="center")`
- validation of accepted alignment strings
- padding, spacing, packing mode, and empty `HPacker` handling

## Call-Site Audit

Read-only source search over `repo/lib`, `repo/examples`, and `repo/doc` found:

- `HPacker` in legend code using `align="baseline"`.
- `HPacker` examples using `align="center"`.
- `VPacker` in legend code using `align="baseline"` or `align="right"`.
- `VPacker` examples using `align="center"`.
- no in-repository public call site using `HPacker(align="top")`,
  `HPacker(align="bottom")`, or `VPacker(align="top"/"bottom")`.

## External Compatibility Risk

External users who compensated for the inverted `HPacker` behavior may see the
intended behavior change. The public hints explicitly discuss this risk and also
identify the direct fix as an acceptable plain-bugfix path.

`VPacker(align="top"/"bottom")` remains a residual ambiguous case because those
names are not the meaningful cross-axis names for a vertical packer. The source
audit found no public in-repository dependency on those aliases. I did not add
axis-specific compatibility shims because that would preserve a legacy
implementation artifact without public intent evidence, while the shared
helper's documented lower/far edge model supports the V1 grouping.
