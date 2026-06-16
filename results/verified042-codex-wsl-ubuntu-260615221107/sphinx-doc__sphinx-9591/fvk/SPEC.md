# FVK Spec

Constructed, not machine-checked.

## Scope

This FVK pass audits the V1 fix for `sphinx-doc__sphinx-9591`: property type
annotations produced by autodoc must cross-reference documented Python types.
The audited source path is:

- producer: `repo/sphinx/ext/autodoc/__init__.py:2726-2732`
- parser: `repo/sphinx/domains/python.py:110-186`
- consumer: `repo/sphinx/domains/python.py:849-867`

## Public Intent Ledger

| ID | Public evidence | Obligation |
| --- | --- | --- |
| E-001 | Issue title: "Cross-references don't work in property's type annotations" | A property type annotation must become cross-reference-capable output. |
| E-002 | Issue example: `@property def end(self) -> Point` | The type token `Point` must be represented as a Python reference target in the property signature. |
| E-003 | Expected behavior: "I expected the documented type in property's type annotation to be cross-referenced." | The required output property is not merely visible text; it must be resolvable as a cross-reference. |
| E-004 | Attribute/variable source paths already use `_parse_annotation()` for `:type:` | Property `:type:` should use the same parser unless public evidence says otherwise. |
| E-005 | Autodoc producer source emits `:type:` from property getter return annotations | The consumer path is the correct repair point; changing annotation discovery is not required. |

The standalone ledger is mirrored in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

## Formal Model

The model in `fvk/mini-python-domain.k` abstracts the property type handling
fragment into three observable values:

- `txt(": ")` for the visible separator required by existing signatures.
- `xref(T)` for a parsed Python type-reference node.
- `descAnn(...)` for the signature annotation node appended to `signode`.

This abstraction preserves the defect axis. A failing pre-fix instance maps
`Point` to plain text inside `descAnn`; a passing V1 instance maps `Point` to
`xref("Point")`. Therefore the model distinguishes the issue's wrong and right
outputs.

## Claims

`fvk/python-property-spec.k` contains two reachability claims:

- `PROPERTY-TYPE-XREF`: for every non-empty type string `T`, handling a
  property `:type:` option appends `descAnn(txt(": "), xref(T))`.
- `PROPERTY-NO-TYPE-FRAME`: without a `:type:` option, handling the property
  type suffix leaves the signature node list unchanged.

Frame conditions captured in prose and proof obligations:

- The base `PyObject.handle_signature()` output and return tuple are preserved.
- The public method signature and directive option schema are unchanged.
- The autodoc producer remains unchanged because it already emits `:type:`.

## Adequacy

The formal-English round trip is in `fvk/FORMAL_SPEC_ENGLISH.md`; the comparison
against intent is in `fvk/SPEC_AUDIT.md`. All claims pass the adequacy gate. No
claim preserves the legacy plain-text property behavior as intended.

## Machine-Check Commands

These commands are emitted for later verification only and were not run:

```sh
kompile fvk/mini-python-domain.k --backend haskell
kast --backend haskell fvk/python-property-spec.k
kprove fvk/python-property-spec.k --definition fvk/mini-python-domain-kompiled
```
