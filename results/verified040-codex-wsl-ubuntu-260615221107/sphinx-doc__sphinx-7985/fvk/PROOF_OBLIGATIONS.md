# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Intent adequacy

- Claim: the formal spec covers the public issue, not merely V1 behavior.
- Evidence: IE1 and IE2 in `fvk/SPEC.md`.
- Discharge: C1 states the reported relative missing local target is broken.
- Findings: F1.
- Status: discharged by spec and V2 code.

## PO2: Local checking reaches non-HTTP(S) relative links

- Claim: a relative local URI no longer exits early as `local`.
- Evidence: issue's `doesntexist` target.
- Code points: `check()` in `sphinx/builders/linkcheck.py` now routes non-HTTP(S)
  URIs through `_check_local_link()` unless ignored or explicitly unchecked.
- Verification condition: for `URI` not empty, not `mailto:`, not `ftp:`, not
  HTTP(S), and not ignored, execution reaches `_check_local_link(URI, DOC)`.
- Findings: F1.
- Status: discharged by source inspection.

## PO3: Missing relative target becomes broken

- Claim: if normalized target `T` is not a known Sphinx document URI, not a
  visible source-tree file, not absolute, not scheme-qualified, and does not
  escape the source directory, `_check_local_link()` returns
  `("broken", "local file not found")`.
- Evidence: issue reproducer.
- Code points: `_resolve_local_uri()`, `_local_docname_for()`,
  `_local_target_exists()`, `_check_local_link()`.
- Verification condition: `resolved = (T, A)`, `target_docname is None`, and
  `_local_target_exists(T, None) == False` implies status `broken`.
- Findings: F1, F5.
- Status: discharged for modeled filesystem snapshot.

## PO4: Existing local document or source file remains local

- Claim: a local link to a known Sphinx document URI or source-tree file is not
  marked broken.
- Evidence: public hint limits checking to Sphinx-known content and warns about
  deploy-only files.
- Code points: `prepare_writing()` builds `_local_uri_to_docname`;
  `_local_target_exists()` accepts known docnames or existing source paths.
- Verification condition: `target_docname != None` or `path.exists(srcdir/T)`
  implies status `local`, subject to anchor PO5.
- Findings: F5.
- Status: discharged with residual deployment boundary.

## PO5: Local document anchors obey anchor config

- Claim: if a local URI targets a known Sphinx document and has a non-ignored
  fragment, then with `linkcheck_anchors=True` the fragment must exist in that
  document's id set.
- Evidence: public `linkcheck_anchors` and `linkcheck_anchors_ignore` docs.
- Code points: `prepare_writing()` builds `_local_anchors`;
  `_resolve_local_uri()` extracts and ignores configured anchors;
  `_local_anchor_exists()` checks ids; `_check_local_link()` returns broken on
  missing anchors.
- Verification condition: `anchor != ""`, `anchor not ignored`, `anchors=True`,
  `target_docname != None`, and `anchor notin DOC_ANCHORS[target_docname]`
  implies status `broken`.
- Findings: F2.
- Status: discharged by V2.

## PO6: Uncheckable local URI forms do not create false broken results

- Claim: absolute local paths, scheme-qualified non-HTTP URIs, netloc URIs, and
  source-directory escapes are left `local`.
- Evidence: public hint about absolute paths and unknown deployment placement.
- Code points: `_resolve_local_uri()` returns `None` for absolute, scheme, and
  netloc URIs; `_local_target_exists()` returns `None` for `..` escapes; the
  caller maps `None` to `local`.
- Verification condition: `resolved is None` or `exists is None` implies status
  `local`.
- Findings: F3.
- Status: discharged by V2.

## PO7: Optional feature preserves opt-out behavior

- Claim: with `linkcheck_local_links=False`, local links are not validated.
- Evidence: public hint "At least this could be an optional feature."
- Code points: `_check_local_link()` returns `local` immediately; `check()`
  keeps anchor-only links `unchecked` when the feature is disabled.
- Verification condition: `LOCAL_LINKS=False` and non-anchor local URI implies
  `local`; `LOCAL_LINKS=False` and `URI` starts with `#` implies `unchecked`.
- Findings: F4.
- Status: discharged.

## PO8: Broken local links affect build status and outputs like broken remote links

- Claim: a broken local result must write a broken entry, a JSON status, and set
  status code to failure.
- Evidence: issue expects `make linkcheck` to finish with problems for checked
  broken links; existing remote broken behavior sets `app.statuscode = 1`.
- Code points: `process_result()` handles `status == 'broken'`; `_has_broken`
  feeds `write_doc()` statuscode update.
- Verification condition: any processed broken result implies `_has_broken=True`
  and eventually `app.statuscode=1`.
- Findings: F1.
- Status: discharged.

## PO9: Public compatibility and documentation

- Claim: public docs and make-mode help must describe the broadened builder
  behavior and the new config value.
- Evidence: public docs are the source for builder behavior and config values.
- Code/doc points: `doc/usage/configuration.rst`,
  `doc/usage/builders/index.rst`, `doc/man/sphinx-build.rst`,
  `sphinx/cmd/make_mode.py`.
- Verification condition: user-facing text no longer claims external-only
  checking where linkcheck behavior is summarized, and documents
  `linkcheck_local_links`.
- Findings: F4.
- Status: discharged by V2 docs/help edits.

## PO10: Existing external link behavior is framed

- Claim: HTTP(S) logic, retries, auth, headers, redirects, SSL ignores, and
  remote anchor checks are not changed by local checking.
- Evidence: public docs and existing linkcheck behavior.
- Code points: V2 local branch is before the HTTP(S) cache/network logic; HTTP(S)
  code paths are otherwise unchanged except that `linkcheck_ignore` is checked
  before cache lookup, which is compatible because ignored URLs are not cached.
- Verification condition: for URI starting `http:` or `https:` and not ignored,
  `check_uri()` behavior is unchanged.
- Findings: none.
- Status: discharged by source diff inspection.
