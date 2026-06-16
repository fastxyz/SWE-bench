# Public Evidence Ledger

Constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | prompt / issue | "Cross-references don't work in property's type annotations" | A property type annotation must become cross-reference-capable output. | Encoded by PO-001 and K claim `PROPERTY-TYPE-XREF`. |
| E-002 | prompt / issue | "`@property def end(self) -> Point`" and expected documented type cross-reference | For the issue exemplar, `Point` must be represented as a Python pending cross-reference target. | Encoded by PO-001. |
| E-003 | source: `repo/sphinx/ext/autodoc/__init__.py:2726-2732` | `PropertyDocumenter` reads the property getter signature and emits `:type:` from the return annotation. | The producer side already supplies the type option; the consumer must parse it. | Supports keeping autodoc unchanged. |
| E-004 | source: `repo/sphinx/domains/python.py:110-186` | `_parse_annotation()` converts text annotation nodes to `type_to_xref(...)`. | Reusing `_parse_annotation()` is the existing project mechanism for type cross-reference nodes. | Encoded by PO-001 and PO-002. |
| E-005 | source: `repo/sphinx/domains/python.py:659-666` and `:820-826` | Variables and attributes parse their `:type:` option with `_parse_annotation()`. | Properties should use the same parser for the same `:type:` semantic role. | Encoded by PO-002. |
| E-006 | source: `repo/sphinx/domains/python.py:859-867` | V1 property handling now parses `typ` and appends `nodes.Text(': ')` plus parsed annotation nodes. | V1 implements the intended consumer-side behavior. | Confirmed by proof; not used as intent by itself. |
| E-007 | compatibility search | `PyProperty` is registered as the `property` directive handler and no override of `PyProperty.handle_signature()` was found. | The public method signature and dispatch shape should remain unchanged. | Encoded by PO-004 and PO-005. |
