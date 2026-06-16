# Iteration Guidance

Status: constructed, not machine-checked.

## V2 Decisions

- Keep V1's core local target check. It discharges PO1-PO4 for the reported
  `doesntexist` case.
- Add local document anchor checking. Finding F2 showed V1 was incomplete
  against PO5 and the public `linkcheck_anchors` contract.
- Treat absolute local paths as uncheckable. Finding F3 showed V1 could violate
  PO6 by resolving deployment-root paths against `srcdir`.
- Document the new configuration value and broaden public linkcheck wording.
  Finding F4 showed V1 had a compatibility/documentation gap against PO9.
- Keep source-tree file acceptance as a documented boundary. Finding F5 is a
  residual risk, but not enough public evidence exists to reject source-visible
  files as local targets.

## Tests To Add Later

Do not add or run tests in this benchmark session. Future public tests should
cover:

- Relative missing local link: `doesntexist` reports `broken`, writes JSON
  status `broken`, writes `output.txt`, and sets `app.statuscode = 1`.
- Existing local document link: `other.html` remains `local`.
- Missing local document anchor: `other.html#missing` reports `broken` when
  `linkcheck_anchors = True`.
- Ignored local anchor: `other.html#!dynamic` remains `local` with the default
  `linkcheck_anchors_ignore`.
- Anchor-only local link: `#missing` is checked against the current document
  when `linkcheck_local_links = True`.
- Opt-out: with `linkcheck_local_links = False`, relative local links remain
  `local` and anchor-only links remain `unchecked`.
- Absolute path: `/doesntexist` remains `local`, not broken.
- External HTTP(S) linkcheck behavior remains unchanged.

## Machine Check To Run Later

The following commands are intentionally not run here:

```sh
kompile fvk/mini-linkcheck.k --backend haskell
kast --backend haskell fvk/linkcheck-spec.k
kprove fvk/linkcheck-spec.k
```

Before relying on test-redundancy claims, harden the abstract `.k` files into a
fully compilable K model of the relevant Python/Sphinx operations and require
`kprove` to return `#Top`.

## Residual Questions

- Should source-tree files be accepted as valid local targets, or should the
  checker restrict itself strictly to generated Sphinx document URIs? Current V2
  accepts source-visible files as a pragmatic compatibility choice.
- Should linkcheck model post-transform/generated anchors more precisely than
  stored doctree ids? Current V2 uses doctree ids visible through
  `env.get_doctree()`.
- Should protocol-relative URLs such as `//example.com/path` be treated as
  external HTTP(S) links in a future change? This is outside the current issue
  and remains legacy behavior.
