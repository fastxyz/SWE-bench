# Proof Obligations

Constructed, not machine-checked.

## PO-001: Property type names become Python cross-reference nodes

- Intent source: E-001, E-002, E-003.
- Formal claim: `PROPERTY-TYPE-XREF`.
- Precondition: a `py:property` directive has a non-empty `:type:` option `T`,
  including the issue exemplar `Point`.
- Required postcondition: the appended signature annotation contains
  `txt(": ")` followed by `xref(T)`.
- Status: discharged by V1 and the constructed proof.
- Related finding: F-001.

## PO-002: Properties reuse the established annotation parser

- Intent source: E-004.
- Formal claim: `PROPERTY-TYPE-XREF`, plus source inspection of
  `_parse_annotation()`.
- Precondition: the annotation text is in the domain already handled by
  `_parse_annotation()` or its fallback to `type_to_xref`.
- Required postcondition: property `:type:` annotations are parsed through the
  same mechanism used by variables, attributes, parameters, and return
  annotations.
- Status: discharged by V1.
- Related finding: F-001.

## PO-003: Untyped properties are frame-preserved

- Intent source: Intent 4.
- Formal claim: `PROPERTY-NO-TYPE-FRAME`.
- Precondition: no `:type:` option is present.
- Required postcondition: no type annotation suffix is appended by the property
  type-handling fragment.
- Status: discharged by constructed proof.
- Related finding: none open.

## PO-004: Autodoc producer remains unchanged

- Intent source: E-005.
- Formal claim: prose frame obligation in `SPEC.md`; source path inspection.
- Precondition: property getter has a return annotation and
  `autodoc_typehints != 'none'`.
- Required postcondition: `PropertyDocumenter` still emits `:type:` from the
  return annotation; the repair is limited to consuming that option.
- Status: discharged by source inspection; no code change required.
- Related finding: F-002.

## PO-005: Public API and directive compatibility are preserved

- Intent source: E-007 and compatibility audit.
- Formal claim: `PROPERTY-SUPER-FRAME` and `PROPERTY-COMPATIBILITY` in
  `FORMAL_SPEC_ENGLISH.md`.
- Precondition: public code invokes the Python domain `property` directive or
  `PyProperty.handle_signature`.
- Required postcondition: method signature, directive option schema, return
  tuple, base signature nodes, and registration remain compatible.
- Status: discharged by source inspection and compatibility audit.
- Related finding: F-003.
