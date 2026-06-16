# FVK Spec for sphinx-doc__sphinx-7454

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Intent Specification

I-001. With `autodoc_typehints = "signature"`, a direct return annotation
`None` must render as a clickable intersphinx link to Python's documentation for
the `None` singleton.

I-002. With `autodoc_typehints = "description"`, `None` already links to the
same Python documentation target. Signature mode must be consistent with that
behavior.

I-003. Non-`None` annotations that already link in signature mode, such as
`int`, must keep their current cross-reference role and link behavior.

I-004. The fix must be minimal and must not change public directive signatures,
autodoc configuration names, or the returned shape of `_parse_annotation()`.

## Public Evidence Ledger

E-001, prompt, encoded: "With `autodoc_typehints='description'`, a function
that returns `None` generates a clickable link to None's documentation." This
imposes the parity obligation in I-002.

E-002, prompt, encoded: "With `autodoc_typehints='signature'`, the `None` in
the signature is not clickable." This identifies the legacy behavior as the
bug, not as a behavior to preserve.

E-003, prompt, encoded: "Expected behavior: That `None` in a type hint links to
the documentation for the `None` singleton regardless of whether 'description'
or 'signature' mode is used." This imposes I-001 and I-002.

E-004, prompt, encoded: the reproducer shows `f2() -> int` linking in signature
mode. This imposes I-003 as a frame condition.

E-005, implementation, encoded: `PyField.make_xref()` and
`PyTypedField.make_xref()` change `rolename == "class"` and `target == "None"`
to `rolename = "obj"`. This is implementation evidence for the role that
already satisfies description-mode intent.

E-006, implementation, encoded: `_parse_annotation()` is used for both
signature parameter annotations and return annotations; it creates
`pending_xref` nodes through its internal `make_xref()` helper.

E-007, implementation, encoded: intersphinx registers `missing-reference` at
the default priority and the Python domain registers `builtin_resolver` at
priority 900; event priorities are ascending. Therefore intersphinx gets the
first chance to resolve a `py:obj` `None` reference before the built-in fallback
can return plain text.

## Formal Model

The formal core is in:

- `fvk/mini-sphinx-annotation.k`
- `fvk/sphinx-7454-spec.k`

The model abstracts only the property under verification:

- `makeXref(T)` models the internal helper in `_parse_annotation()`.
- `classRole` models `reftype="class"`.
- `objRole` models `reftype="obj"`.
- `signatureLink(hasPyObjRoleNone, T)` models the signature-mode annotation
  path through `make_xref()` and then the intersphinx resolver, under the public
  issue's configured Python inventory containing the `None` singleton.

This abstraction preserves the property axis under test: the `reftype` field of
the generated pending cross-reference. It distinguishes the failing case
`xref(classRole, "None") -> plain("None")` from the passing case
`xref(objRole, "None") -> external("...#None")`.

## Claims

C-001. `makeXref("None")` reaches `xref(objRole, "None")`.

C-002. For every string `T` where `T != "None"`, `makeXref(T)` reaches
`xref(classRole, T)`.

C-003. Under an intersphinx inventory containing Python's `None` object-role
entry, `signatureLink(hasPyObjRoleNone, "None")` reaches the external URL
`https://docs.python.org/3/library/constants.html#None`.

C-004. `makeXref("int")` reaches `xref(classRole, "int")`, preserving the
known working signature-mode type-link path for `int`.

## Adequacy Audit

A-001. C-001 and C-003 pass I-001/I-002: they state the exact signature-mode
role and link result required for direct `None` annotations.

A-002. C-002 and C-004 pass I-003: they preserve class-role behavior for every
non-`None` annotation token and explicitly for the prompt's `int` example.

A-003. C-001 through C-004 pass I-004: the claims constrain only the internal
role value placed on generated pending references; no public API shape changes.

A-004. The proof scope is intentionally partial: it proves role selection and
the modeled intersphinx ordering for the issue's path. It does not prove the
full behavior of Sphinx's parser, docutils transforms, HTML writer, network
fetching of inventories, or build termination.

## Public Compatibility Audit

PCA-001. Changed symbol: `_parse_annotation()` internal helper behavior only.
Its Python function signature remains unchanged.

PCA-002. Return shape remains `List[Node]`; `pending_xref` still contains the
same text content and `refdomain="py"`.

PCA-003. Public callers found in source are the Python domain signature parser
for parameters and return annotations. Both consume child nodes, not a public
API contract for `reftype="class"` on `None`.

PCA-004. No public subclass, override, directive option, config value, or event
handler signature changes.

## Non-executed Machine-check Commands

These commands are recorded for later machine checking only. They were not run.

```sh
kompile fvk/mini-sphinx-annotation.k --backend haskell
kast --backend haskell fvk/sphinx-7454-spec.k
kprove fvk/sphinx-7454-spec.k
```
