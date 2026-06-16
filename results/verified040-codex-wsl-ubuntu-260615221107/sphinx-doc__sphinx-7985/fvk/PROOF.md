# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Trusted Base

- The abstraction in `fvk/SPEC.md` faithfully models the relevant parts of
  `CheckExternalLinksBuilder.check()`, `_check_local_link()`,
  `_resolve_local_uri()`, `_local_docname_for()`, `_local_target_exists()`,
  `_local_anchor_exists()`, and `process_result()`.
- `env.found_docs`, doctree ids, and filesystem existence are treated as finite
  maps/sets fixed at `prepare_writing()` time.
- Python library operations `urlparse`, `unquote`, `quote`, `posixpath.join`,
  `posixpath.normpath`, `path.abspath`, and `path.exists` obey their documented
  meanings.
- This is a partial-correctness proof for the local-link classification path.
  Thread scheduling, network behavior, filesystem races, and build termination
  are outside the proof.

## Non-Executed Machine-Check Commands

The FVK method normally emits K files and runs these commands later. This task
forbids execution, so these are recorded only:

```sh
kompile fvk/mini-linkcheck.k --backend haskell
kast --backend haskell fvk/linkcheck-spec.k
kprove fvk/linkcheck-spec.k
```

Expected result after a future machine check: `#Top` for claims C1-C9 in
`fvk/SPEC.md` and the corresponding abstract claims in `fvk/linkcheck-spec.k`,
after making any syntax adjustments required by a real K toolchain.

## Proof Sketch by Obligation

### PO2: Non-HTTP(S) relative links reach local checking

Symbolic execution of `check()` case-splits on the URI prefix:

1. `URI == ""`, `mailto:`, or `ftp:` reaches `unchecked` by the first guard.
2. `URI` matching `linkcheck_ignore` reaches `ignored`.
3. `URI.startswith("#") and not linkcheck_local_links` reaches `unchecked`.
4. Otherwise, if `URI` is not HTTP(S), execution calls `_check_local_link()`.
5. HTTP(S) URIs continue to the existing cache/network path.

For the issue URI `doesntexist`, cases 1-3 and 5 are false, so case 4 is forced.

### PO3: Missing relative target is broken

For `URI = "doesntexist"` from `DOC = "index"`:

1. `_resolve_local_uri()` parses no scheme, no netloc, no fragment, and relative
   path `doesntexist`.
2. `get_target_uri("index")` is `index + link_suffix`; its directory is empty,
   so normalized target remains `doesntexist`.
3. `_local_docname_for("doesntexist", "index")` returns `None` when neither the
   raw nor quoted target is in `_local_uri_to_docname`.
4. `_local_target_exists("doesntexist", None)` returns `False` when the target
   does not escape and `path.exists(srcdir/doesntexist)` is false.
5. `_check_local_link()` maps `False` to `("broken", "local file not found")`.

This discharges C1 and the issue reproducer.

### PO4: Existing local target remains local

Case split on target kind:

1. If `target_docname` is found in `_local_uri_to_docname`, `_local_target_exists`
   returns `True`.
2. If no docname is found but the normalized target is inside `srcdir` and
   `path.exists(full_target)` is true, `_local_target_exists` returns `True`.
3. `_check_local_link()` maps `True` to `local`, unless PO5's anchor side
   condition fails.

Thus known Sphinx document URIs and visible source-tree files are preserved as
non-broken local links.

### PO5: Local anchors obey anchor configuration

For `URI = "target.html#missing"`:

1. `_resolve_local_uri()` returns `(target.html, missing)` unless the fragment
   matches `linkcheck_anchors_ignore`, in which case the anchor is erased.
2. `_local_docname_for("target.html", DOC)` returns `TARGETDOC` when the target
   URI was populated by `prepare_writing()`.
3. `_local_target_exists("target.html", TARGETDOC)` returns `True`.
4. If `linkcheck_anchors` is false or the anchor was ignored, `_check_local_link`
   returns `local`.
5. If `linkcheck_anchors` is true and
   `_local_anchor_exists(TARGETDOC, "missing")` is false, `_check_local_link`
   returns `("broken", "Anchor 'missing' not found")`.

This discharges C7 and C8 and fixes F2.

### PO6: Uncheckable URI forms do not create false broken results

For absolute path `URI = "/doesntexist"`:

1. `_resolve_local_uri()` sees parsed path beginning with `/` and returns
   `None`.
2. `_check_local_link()` maps `resolved is None` to `local`.

For scheme-qualified or netloc URIs, `_resolve_local_uri()` also returns `None`.
For paths that normalize outside the source directory, `_local_target_exists()`
returns `None`. In all cases `_check_local_link()` returns `local`, not broken.
This discharges C4 and fixes F3.

### PO7: Optional feature

If `linkcheck_local_links` is false:

1. Anchor-only URIs are caught in `check()` and remain `unchecked`, matching
   pre-existing behavior.
2. Other local URIs reach `_check_local_link()` and return `local` immediately.

No target or anchor lookup occurs. This discharges C5 and C6.

### PO8: Broken status propagation

For any result tuple with `status == "broken"`:

1. `process_result()` writes the warning/log output and output files through the
   existing broken branch.
2. V2 sets `_has_broken = True` in that same branch.
3. At the end of `write_doc()`, `_has_broken` implies `app.statuscode = 1`.

This covers both external broken links and newly broken local links without
caching relative local URIs globally.

### PO10: External frame condition

For HTTP(S) URIs not matching `linkcheck_ignore`, all local-only guards are
false and execution reaches the pre-existing cache/network branch. The network
checker `check_uri()` is unchanged. Moving ignore matching before cache lookup
does not alter intended external behavior because ignored URIs should not be
checked regardless of cache state.

## Test Redundancy

No test removal is recommended. The proof is not machine-checked, and the task
forbids modifying tests. Future tests should cover the FVK findings rather than
being removed.

## Residual Risks

- The source-tree file acceptance rule is a pragmatic boundary. A file visible
  in the source directory may still be omitted by a custom deployment.
- Anchors added only by late post-transforms outside stored doctree ids could
  require a richer Sphinx-specific model.
- The proof abstracts over threads and filesystem races.
