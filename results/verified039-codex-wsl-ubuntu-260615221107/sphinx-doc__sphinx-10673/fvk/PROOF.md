# Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, or `kprove`
commands were run in this environment.

## Reproduce the machine check later

From the workspace root, in an environment with K installed:

```sh
kompile fvk/mini-toctree.k --backend haskell
kast --backend haskell fvk/toctree-generated-pages-spec.k
kprove fvk/toctree-generated-pages-spec.k
```

Expected result: `#Top` for all claims. Until that is observed, the proof
remains constructed evidence only.

## Claims proved by construction

The claims in `toctree-generated-pages-spec.k` prove partial correctness of the
abstract toctree dataflow:

* generated entries parse to `entries` without `includefiles` or warnings;
* generated entries resolve through the standard-domain label map;
* ordinary source documents and unknown missing documents preserve existing
  behavior;
* section-number and figure-number traversal skip generated entries.

## Symbolic proof sketch

### Parser generated path

Given `generatedTarget(REF, LABELS, FOUND)`, the `parse(TITLE, REF)` rule matches
the generated rule in `mini-toctree.k`. One semantic step rewrites `<k>` to
`.K`, appends `entry(TITLE, REF)` to `<entries>`, and frames
`<includefiles>` and `<warnings>` unchanged. By Consequence, the concrete
preconditions for `genindex`, `modindex`, and `search` imply
`generatedTarget`, because `generatedName` is true for those refs and the target
is absent from `FOUND`. This discharges PO-1.

### Resolver generated path

Given `generatedTarget(REF, LABELS, FOUND)`, the `resolve(TITLE, REF)` rule
looks up the target and default title using `targetOf` and `titleOf`, then
appends `link(targetOf(...), displayTitle(...))`. `displayTitle("", DEFAULT)`
reduces to `DEFAULT`; a non-empty explicit title reduces to that explicit title.
For `modindex`, `targetOf("modindex", LABELS)` is `py-modindex`. This discharges
PO-2.

### Source and unknown preservation

If `DOC in FOUND`, the source-document parse rule fires before the unknown rule
and appends both an entry and includefile. If `REF` is not in `FOUND` and
`generatedTarget` is false, the unknown rule appends `warning(REF)` and leaves
entries/includefiles unchanged. These mutually exclusive side conditions
discharge PO-3.

### Numbering traversal

For generated refs, both `assignSection(REF)` and `assignFigure(REF)` match skip
rules that rewrite `<k>` to `.K` and frame numbering/warning cells unchanged.
This is the proof obligation V1 did not fully satisfy for section numbering.
V2's source code now mirrors the proof: both collectors test
`get_toctree_generated_target` in the same skip condition. This discharges PO-4.

## Adequacy check

`FORMAL_SPEC_ENGLISH.md` paraphrases each claim. `SPEC_AUDIT.md` compares those
paraphrases to the intent-only obligations in `INTENT_SPEC.md` and marks every
claim as pass. The proof therefore targets the public issue behavior rather than
merely restating the candidate implementation.

## Residual risk

This is a mini semantics over the toctree dataflow, not a full Python or Sphinx
semantics. It is adequate for distinguishing the defect named in the issue
because the observable axes are represented: entry membership, includefile
membership, warning emission, link target/title, and numbering traversal. The
proof is partial correctness only and is not machine-checked.

## Test recommendation

No test files were edited. If machine-checking later returns `#Top`, unit tests
that only assert the in-domain claims for `genindex`, `modindex`, and `search`
would be subsumed by the proof. Integration tests for real Sphinx HTML output,
builder availability, incremental rebuilds, and non-HTML builders should be kept
because the mini semantics does not cover those full execution paths.
