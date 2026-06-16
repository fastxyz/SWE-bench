# FVK Proof for sphinx-doc__sphinx-7454

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## What Is Proved

The proof establishes partial correctness of the issue-relevant annotation role
selection:

- Exact annotation text `None` in the Python signature parser produces a
  pending reference with the object role.
- Annotation text other than `None` keeps the existing class role.
- Under the issue's intersphinx condition that Python's object-role inventory
  contains the `None` singleton entry, the signature-mode `None` path reaches
  the external Python documentation URL for `None`.

There are no loops or recursive functions in the changed logic, so no
circularity claim is needed.

## Formal Core

The mini semantics is `fvk/mini-sphinx-annotation.k`. The spec claims are
`fvk/sphinx-7454-spec.k`.

Core rewrite rules:

```k
rule <k> makeXref("None") => xref(objRole, "None") ... </k>
rule <k> makeXref(T:String) => xref(classRole, T) ... </k>
  requires T =/=String "None"
```

Core claims:

```k
claim <k> makeXref("None") => xref(objRole, "None") </k> [all-path]

claim <k> makeXref(T:String) => xref(classRole, T) </k>
  requires T =/=String "None"
  [all-path]

claim
  <k> signatureLink(hasPyObjRoleNone, "None")
   => external("https://docs.python.org/3/library/constants.html#None")
  </k>
  [all-path]
```

## Symbolic Proof Sketch

Step P-001, exact `None`.
Start state: `<k> makeXref("None") </k>`.
The first semantic rule matches exactly and rewrites to
`<k> xref(objRole, "None") </k>`. This proves C-001 and discharges PO-001.

Step P-002, non-`None` frame.
Start state: `<k> makeXref(T) </k>` with side condition
`T =/=String "None"`.
The second semantic rule matches and rewrites to
`<k> xref(classRole, T) </k>`. This proves C-002 and discharges PO-004. With
`T = "int"`, this also proves C-004 and discharges PO-003.

Step P-003, signature-mode link path for `None`.
Start state: `<k> signatureLink(hasPyObjRoleNone, "None") </k>`.
The sequencing rule rewrites it to
`<k> makeXref("None") ~> resolveWith(hasPyObjRoleNone) </k>`.
By P-001, the head becomes `xref(objRole, "None")`.
The resolver sequencing rule rewrites to
`<k> resolve(hasPyObjRoleNone, xref(objRole, "None")) </k>`.
The intersphinx abstraction rule rewrites to
`<k> external("https://docs.python.org/3/library/constants.html#None") </k>`.
This proves C-003 and discharges PO-002.

Step P-004, parser branch coverage.
In source, both the normal parsed-text path and the `except SyntaxError`
fallback path call the same helper `make_xref(text)`. Therefore P-001 applies
to exact `None` on both paths, discharging PO-005.

Step P-005, description-mode parity.
Source inspection shows `PyField.make_xref()` and `PyTypedField.make_xref()`
already map `rolename == "class"` and `target == "None"` to `rolename = "obj"`.
V1 applies the same role choice to signature annotation references, discharging
PO-006.

Step P-006, compatibility.
The V1 diff changes only the local `reftype` expression inside
`_parse_annotation().make_xref()`. It does not change function signatures,
returned node list shape, node text, or public directive/config/event APIs.
This discharges PO-007.

## Adequacy Result

The formal claims match the public issue intent:

- The public issue requires a signature-mode link for `None`; C-001 and C-003
  state that behavior.
- The public issue says `int` already links in signature mode; C-002 and C-004
  preserve it.
- The issue is about mode consistency; P-005 establishes consistency with the
  existing description-mode special case.

No claim preserves the legacy buggy behavior as an invariant. The pre-fix
display where `None` is not linked is treated as SUSPECT legacy behavior.

## Residual Risk

This proof is constructed, not machine-checked. It covers the role-selection
and resolver-order slice needed for the issue, not the whole Sphinx build
pipeline, external inventory downloading, docutils transform machinery, or HTML
writer behavior. Termination is not a concern for the changed branch because it
contains no loop or recursion, but full build termination is outside this
model.

## Non-executed Machine-check Commands

These commands are recorded for later use only.

```sh
kompile fvk/mini-sphinx-annotation.k --backend haskell
kast --backend haskell fvk/sphinx-7454-spec.k
kprove fvk/sphinx-7454-spec.k
```

## Test-redundancy Guidance

No tests were modified. If the K claims are later machine-checked, a unit test
that only asserts `make_xref("None")`/`_parse_annotation("None")` produces
`reftype="obj"` would be subsumed by C-001. Integration tests for autodoc,
intersphinx, and HTML output should be kept because this proof abstracts those
systems.
