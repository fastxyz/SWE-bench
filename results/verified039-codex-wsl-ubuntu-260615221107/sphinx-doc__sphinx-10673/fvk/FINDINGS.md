# Findings

Status: constructed, not machine-checked.

## F1: V1 skipped generated entries only in figure numbering

* Classification: code bug in V1, fixed in V2.
* Evidence: `assign_figure_numbers` had an explicit
  `get_toctree_generated_target` guard, but `assign_section_numbers` still only
  skipped URLs and `self`.
* Input -> observed vs expected: a numbered toctree entry stored as generated
  `modindex` with another real source document named `modindex` already assigned
  could take the `ref in assigned` branch and warn as if a source document were
  duplicated. Expected: generated pages are links, not source doctrees, and
  section numbering should ignore them exactly as figure numbering does.
* Proof obligation: PO-4.
* Resolution: V2 adds the generated-target guard to `assign_section_numbers`.

## F2: V1 parser and resolver satisfy the core issue intent

* Classification: confirmed behavior over the FVK spec.
* Evidence: PO-1 through PO-3 cover the issue examples and the normal-source /
  unknown-missing frame conditions.
* Input -> observed vs expected: `genindex`, `modindex`, and `search` in a
  toctree with no corresponding source document now parse as entries without
  includefiles or warnings, and resolve as links to `genindex`, `py-modindex`,
  and `search` respectively. This matches expected generated-page behavior.
* Resolution: V1 parser/resolver logic stands unchanged in V2.

## F3: Formal core is abstract, not a full Python semantics

* Classification: proof capability gap / escalation boundary.
* Evidence: `mini-toctree.k` models the toctree dataflow relevant to this fix,
  not full Python, docutils, or Sphinx builder execution.
* Input -> observed vs expected: the abstract claims can distinguish the
  reported bug (missing generated target warning) from the desired no-warning
  generated-link behavior, but they do not prove every Python statement in the
  touched functions.
* Resolution: acceptable for this FVK pass as constructed evidence; keep the
  "constructed, not machine-checked" label and run the emitted commands in a real
  environment before using proof results for test-redundancy decisions.

