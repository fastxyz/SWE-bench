# FVK Spec

Status: constructed, not machine-checked.

## Scope

This spec covers the V2 fix for Sphinx toctree handling of generated-page
entries named in the issue: `genindex`, `modindex`, and `search`.

The audited functions/paths are:

* `sphinx.directives.other.TocTree.parse_content`
* `sphinx.environment.adapters.toctree.get_toctree_generated_target`
* `sphinx.environment.adapters.toctree.TocTree.resolve`
* `sphinx.environment.collectors.toctree.TocTreeCollector.assign_section_numbers`
* `sphinx.environment.collectors.toctree.TocTreeCollector.assign_figure_numbers`

## Public intent ledger

See `PUBLIC_EVIDENCE_LEDGER.md`. The controlling obligations are:

* E1/E2: the issue-reported nonexisting-document warnings for the three named
  generated pages must be eliminated.
* E3/E5: generated toctree entries should use the same standard-domain label
  targets as `:ref:`, especially `modindex -> py-modindex`.
* E4/E6: generated pages are not source doctrees and must not be fed to source
  document consumers.

## Contract

Let `G = {genindex, modindex, search}`. Let `label(ref)` be the standard-domain
label tuple `(target_docname, labelid, title)`.

1. Generated-target recognition:
   `get_toctree_generated_target(env, ref)` returns `label(ref)` iff
   `ref in G`, the standard domain has a non-empty target for `ref`, and that
   target is not in `env.found_docs`. Otherwise it returns `None`.
2. Parser generated case:
   if a toctree entry's normal source-document lookup fails and the normalized
   ref is a generated target, parsing appends `(title, ref)` to
   `toctree['entries']`, appends nothing to `toctree['includefiles']`, emits no
   warning, and does not call `env.note_reread()`.
3. Parser preservation:
   URL entries, `self`, and existing source documents keep their previous
   behavior. Unknown non-generated missing documents still emit the existing
   warning and note a reread.
4. Resolver generated case:
   a generated entry resolves to one internal reference node whose `refuri` is
   the standard-domain target document, whose anchor is the standard-domain
   label id if present, and whose display text is the explicit toctree title or
   the standard-domain label title.
5. Collector generated case:
   section-number and figure-number traversal both skip generated entries in the
   same way they skip URLs and `self`, so they never require `env.tocs[ref]` or
   `env.get_doctree(ref)` for generated pages.

## Frame conditions

* No test files are modified.
* No public directive option, node attribute schema required by existing callers,
  warning text, or builder URI behavior is changed.
* Existing source documents keep precedence over generated labels when the normal
  source lookup succeeds.
* Generated entries are not included in document relation or rebuild dependency
  data because those are driven by `includefiles`.

