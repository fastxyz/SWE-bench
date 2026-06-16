# Constructed Proof

Status: constructed, not machine-checked. No K tooling, tests, or Python code
were executed.

## Claims Proved Constructively

1. `VARIABLE-FIELD-NO-XREF`: a variable field configured with `noRole` renders a
   plain label for every name and object-inventory shape.
2. `VARIABLE-FIELD-WITH-TYPE-PRESERVES-TYPE-XREF`: the variable label remains
   plain while the associated type text still becomes a class-role pending xref.
3. `EXPLICIT-REFERENCE-STILL-LINKS`: explicit data references still resolve when
   a matching module-level object exists.

## Proof Sketch

For `VARIABLE-FIELD-NO-XREF`, symbolic execution of
`variableField(noRole, NAME, BODY, OBJECTS)` applies the `noRole` rule in
`mini-sphinx-fields.k`, producing
`renderedField(plain(NAME), plain(BODY))`. The object inventory is framed
because the rule does not inspect it. Since the result has no `pending(...)`
label, no resolver rule can produce `linked(...)` for the variable label.

This corresponds to V1 source behavior: omitting `rolename` causes
`Field.make_xref()` to take its falsey-role branch and return plain content.

For `VARIABLE-FIELD-WITH-TYPE-PRESERVES-TYPE-XREF`, symbolic execution applies
the `variableFieldWithType(noRole, classRole, ...)` rule, producing
`renderedFieldWithType(plain(NAME), pending(classRole, TYPE), plain(BODY))`.
The label cannot link, but the type node remains a pending class reference.

This corresponds to V1 source behavior: `rolename` is absent for the field
argument, but `typerolename='class'` is still present.

For `EXPLICIT-REFERENCE-STILL-LINKS`, symbolic execution applies the explicit
reference rule for `dataRole` with `moduleSameName`, producing
`linked(NAME, "module-data")`. This frames the unchanged resolver behavior for
explicit user-authored roles.

## Machine-Check Commands

These commands are intentionally not executed in this session:

```sh
cd fvk
kompile mini-sphinx-fields.k --backend haskell
kast --backend haskell sphinx-fields-spec.k
kprove sphinx-fields-spec.k
```

Expected result after a future machine check: `kprove` discharges all claims to
`#Top`.

## Test Recommendation

No test files were modified. Because the proof is not machine-checked, no test
removal is recommended. If testing becomes allowed later, keep integration
tests for Sphinx doctree/HTML output and add focused coverage for:

- `:ivar limit:` beside a same-module `.. py:data:: limit` renders the variable
  field label without a link.
- `:ivar limit:` beside another class's `.. py:attribute:: limit` renders the
  field label without a link.
- `:vartype limit: int` still creates a type-reference node.
- Explicit `:py:data:` or `:py:const:` references still resolve normally.

## Residual Risk

The proof is partial and constructed against a mini-model of the relevant
field-rendering behavior, not against a full Python or full docutils/Sphinx K
semantics. The model preserves the property axis that matters here:
plain variable label versus pending/resolved xref. The remaining trust base is
the adequacy of that abstraction and a future successful K machine check.
