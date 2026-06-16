# Formal Spec English

This paraphrases the nontrivial claims in `inset-locator-spec.k`.

## CLAIM-PROVIDED-RENDERER

If `AnchoredLocatorBase.__call__` receives a valid axes object and a non-`None`
renderer, the effective renderer is that provided renderer. The method sets the
locator's axes to the supplied axes, calls extent and offset calculations with
the provided renderer, and reaches the bbox result.

## CLAIM-NONE-RENDERER

If `AnchoredLocatorBase.__call__` receives a valid axes object and
`renderer=None`, and the axes' figure can provide a renderer, the method first
uses `ax.figure._get_renderer()` as the effective renderer. It then sets the
locator's axes to the supplied axes, calls extent and offset calculations with
that effective renderer, and reaches the bbox result.

## CLAIM-NO-LOCATOR-FIGURE-DEPENDENCE

The successful `renderer=None` path does not require `self.figure` on the
locator. The renderer comes from the axes' figure.

## CLAIM-SHARED-BASE

Because `AnchoredSizeLocator` and `AnchoredZoomLocator` use
`AnchoredLocatorBase.__call__`, the renderer fallback applies to both
`inset_axes` and `zoomed_inset_axes`.
