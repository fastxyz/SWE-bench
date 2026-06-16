# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and proof-obligation construction only.

## F1: Pre-fix local relative links were never checked

- Classification: code bug addressed by V1 and retained in V2.
- Evidence: issue says "linkcheck currently doesn't check local (internal)
  links"; reproducer uses `.. _local-link: doesntexist`; observed output shows
  `-local-   doesntexist`.
- Input -> observed vs expected:
  `URI = "doesntexist"` from `index.rst` -> pre-fix observed status `local`;
  expected status `broken` with a missing-local-target reason.
- Related obligations: PO1, PO2, PO3, PO8.
- Resolution: V2 checks relative local links through `_check_local_link()` and
  returns `broken` when neither a Sphinx document URI nor a visible source-tree
  file exists.

## F2: V1 did not check local document anchors

- Classification: code bug found by FVK audit, fixed in V2.
- Evidence: public docs for `linkcheck_anchors` say Sphinx checks validity of
  `#anchor`s; once local links are in scope, local document anchors are part of
  that behavior.
- Input -> observed vs expected:
  `URI = "target.html#missing"` where `target.html` maps to a known Sphinx
  document but `"missing"` is absent from that doctree's ids -> V1 observed
  status `local`; expected status `broken` with `Anchor 'missing' not found`
  when `linkcheck_anchors` is true.
- Related obligations: PO4, PO5.
- Resolution: V2 records doctree ids in `prepare_writing()` and checks local
  document fragments unless the anchor is ignored or anchor checking is disabled.

## F3: V1 could falsely break absolute local links

- Classification: code bug found by FVK audit, fixed in V2.
- Evidence: public hint says absolute local hyperlinks are hard because Sphinx
  does not know where the document will be placed.
- Input -> observed vs expected:
  `URI = "/doesntexist"` -> V1 normalized it to `doesntexist` and could report
  `broken`; expected status is `local` because the deployment root is unknown.
- Related obligations: PO6.
- Resolution: V2 treats absolute local paths as uncheckable and leaves them
  `local`.

## F4: V1 added an undocumented public config value

- Classification: public compatibility/documentation gap, fixed in V2.
- Evidence: public hint supports an optional feature; V1 added
  `linkcheck_local_links` but did not document it.
- Input -> observed vs expected:
  A user reading linkcheck configuration docs -> V1 did not expose the opt-out;
  expected docs identify the flag and default behavior.
- Related obligations: PO9.
- Resolution: V2 documents `linkcheck_local_links` and updates public linkcheck
  descriptions from "external links" to "links".

## F5: Local source-tree file validity remains a pragmatic assumption

- Classification: residual risk / assumption, not a V2 blocker.
- Evidence: the public hint says only Sphinx-known content can be checked, and
  deploy-script files may be unknowable. Sphinx can see source-tree files, but
  not every source-tree file is necessarily emitted in every output deployment.
- Input -> observed vs expected:
  `URI = "asset.pdf"` and `asset.pdf` exists under the source directory -> V2
  reports `local`; expected under the chosen spec is `local`. A deployment that
  does not copy that file could still produce a broken deployed link.
- Related obligations: PO3, PO6.
- Resolution: record as a documented boundary. Projects that need stricter
  generated-output-only checking should refine the spec or disable/ignore those
  links.

## F6: Formal proof is constructed but not machine-checked

- Classification: proof honesty boundary.
- Evidence: task forbids running tests, Python, `kompile`, or `kprove`.
- Input -> observed vs expected:
  Proof artifacts -> observed no machine result; expected label is
  "constructed, not machine-checked."
- Related obligations: all.
- Resolution: `fvk/PROOF.md` includes non-executed commands and keeps test
  removal conditioned on future machine checking.
