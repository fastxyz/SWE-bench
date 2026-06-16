## FVK audit outcome

The FVK audit found that V1 fixed the reported missing relative local-link check
but was incomplete against the broader intent captured in `fvk/SPEC.md`.

## Code and documentation decisions

`repo/sphinx/builders/linkcheck.py`

- Kept V1's default-on local checking and missing-target behavior. This is
  justified by `fvk/FINDINGS.md` F1 and `fvk/PROOF_OBLIGATIONS.md` PO1-PO3.
- Added local document anchor checking. V1 returned `local` for
  `target.html#missing`; F2 and PO5 require a broken result when the document is
  known, the anchor is not ignored, and `linkcheck_anchors` is true.
- Changed absolute local paths from source-root-relative checking to uncheckable
  local status. F3 and PO6 trace this to the public hint that absolute local
  paths cannot be checked reliably because deployment placement is unknown.
- Preserved the opt-out behavior. PO7 justifies `linkcheck_local_links=False`
  returning local/unchecked statuses without target validation.
- Kept `_has_broken` instead of caching local failures in `self.broken`. PO8
  requires broken local links to fail the build, while relative local URI cache
  keys would be unsound across documents.

`repo/doc/usage/configuration.rst`

- Documented `linkcheck_local_links`, including the default and uncheckable
  absolute/scheme/escaping path behavior. This addresses F4 and PO9.

`repo/doc/usage/builders/index.rst`, `repo/doc/man/sphinx-build.rst`, and
`repo/sphinx/cmd/make_mode.py`

- Updated user-facing summaries from external-only checking to all-link/local
  checking. This addresses the compatibility/documentation gap in F4 and PO9.

## Decisions to keep V1 behavior

- Source-tree files remain accepted as valid local targets. F5 records the
  residual deployment risk, but PO4 permits this as a pragmatic Sphinx-visible
  boundary because the issue hint warns only that deploy-script-only files are
  unknowable.
- HTTP(S) behavior was left structurally unchanged. PO10 frames retries, auth,
  redirects, remote anchors, and existing caches as preserved behavior.

## Verification status

The proof in `fvk/PROOF.md` is constructed, not machine-checked. The task
forbids running tests, Python, `kompile`, `kast`, or `kprove`, so the emitted
commands are recorded for future use only. `fvk/mini-linkcheck.k` and
`fvk/linkcheck-spec.k` were added as abstract formal-core artifacts to support
the claims in `fvk/SPEC.md` and `fvk/PROOF_OBLIGATIONS.md`.
