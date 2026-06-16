# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed symbols

* New helper: `sphinx.environment.adapters.toctree.get_toctree_generated_target`
* Existing methods touched without signature changes:
  * `sphinx.directives.other.TocTree.parse_content`
  * `sphinx.environment.adapters.toctree.TocTree.resolve`
  * `sphinx.environment.collectors.toctree.TocTreeCollector.assign_section_numbers`
  * `sphinx.environment.collectors.toctree.TocTreeCollector.assign_figure_numbers`

## Compatibility result

No public method signature, directive option, return type, or virtual dispatch
call shape changed. The new helper is internal to Sphinx's toctree
implementation and has two internal consumers. Existing source-document,
external URL, `self`, duplicate-entry, excluded-document, and missing-document
paths preserve their previous behavior except for the three generated labels
named by the issue.

No public subclass override was found for the changed method signatures because
no signature changed. No test files were modified.

