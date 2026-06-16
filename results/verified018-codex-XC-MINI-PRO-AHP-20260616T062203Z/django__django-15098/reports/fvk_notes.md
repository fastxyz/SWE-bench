# FVK Notes

## Decision Summary

V1 stands unchanged after the FVK audit. The audit found no additional
public-intent obligation that requires another source edit.

## Source Decisions

`repo/django/utils/translation/trans_real.py`

Decision: keep the V1 exact configured-language first-segment branch.

Reasoning: `fvk/FINDINGS.md` F1 shows this branch fixes `/en-latn-us/`, and F2
shows it participates in fixing `/en-Latn-US/`. `fvk/PROOF_OBLIGATIONS.md` PO1
and PO2 state the exact and case-insensitive configured-language obligations.
The source branch discharges those obligations by extracting the first path
segment, validating it with `language_code_re`, and comparing it against
`get_languages()`.

Decision: keep the original `language_code_prefix_re` fallback unchanged.

Reasoning: F3 identifies the regex-only overmatch hazard, and PO3 requires that
a non-configured three-part slug such as `/de-simple-page/` not fall back to
`de`. V1 satisfies this by not broadening the regex. F4 and PO4 also require
that existing legacy fallback behavior remain delegated to the old code path.

`repo/django/urls/resolvers.py`

Decision: keep the V1 case-insensitive prefix comparison in
`LocalePrefixPattern.match()`.

Reasoning: F2 traces the BCP 47 case path through activation and resolver
matching. PO5 requires case-insensitive comparison while preserving original
prefix-length stripping. The V1 expression
`path[:len(language_prefix)].lower() == language_prefix.lower()` discharges
that obligation. PO6 confirms that empty-prefix behavior remains compatible.

## No Additional Source Edit

F5 concludes that PO1 through PO7 cover the public intent for this issue. The
compatibility audit in `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` found no signature,
return-shape, or public caller breakage. Therefore there was no FVK-justified
source change beyond V1.

## Proof Status

The FVK proof is constructed, not machine-checked. I did not run tests, Python,
`kompile`, `kast`, or `kprove`, per the task constraints. The commands needed
to machine-check later are recorded in `fvk/PROOF.md`.
