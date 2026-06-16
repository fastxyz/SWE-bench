# Intent Spec

Status: constructed from public intent only, before trusting candidate behavior.

## Required behavior

1. `ContourSet` must support a public `set_paths(paths)` call.
2. Calling `cs.set_paths(transformed_paths)` must be the supported equivalent
   of replacing the whole sequence returned by `cs.get_paths()` with
   `transformed_paths`.
3. After the call, contour consumers that read the `ContourSet` path store must
   observe the supplied path sequence.
4. The setter should follow the local `PathCollection.set_paths` pattern:
   assign the path sequence and mark the artist stale.
5. The change must remain scoped to `ContourSet`; it must not change unrelated
   collection subclasses whose path setters have specialized semantics.
6. Existing contour path-cache views derived from `_paths` must not be treated
   as authoritative after `_paths` is replaced.

## Domain

The intended in-domain call is a `ContourSet` instance and a sequence of
`matplotlib.path.Path` objects suitable for the contour levels.  The public
issue does not require shape validation, copying, or conversion.

