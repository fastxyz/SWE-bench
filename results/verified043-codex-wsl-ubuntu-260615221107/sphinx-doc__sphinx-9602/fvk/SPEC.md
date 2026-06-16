# FVK Specification for sphinx-doc__sphinx-9602

Status: constructed from public intent and source inspection; not machine-checked.
No tests, Python, or K tooling were run.

## Scope

The audited unit is `sphinx.domains.python._parse_annotation(annotation, env)`.
The relevant observable is the returned sequence of annotation nodes, specifically
which fragments become Python-domain `pending_xref` nodes and which remain literal
signature text.

The source call sites show `_parse_annotation()` is used for function parameter
annotations, return annotations, attribute `:type:`, variable `:type:`, and property
`:type:` annotations. Its public signature and return shape must remain unchanged.

## Intent Spec

- `I1` Source: `benchmark/PROBLEM.md`.
  Evidence: "When a value is present in a type annotation as `Literal`, sphinx will
  treat the value as a `py:class`."
  Obligation: values inside `Literal[...]` are data values, not Python class
  targets.
  Status: encoded by `PO-001`, `PO-002`, and `PO-003`.

- `I2` Source: `benchmark/PROBLEM.md`.
  Evidence: "`Literal[True]` (or whatever literal value) should be present in the
  type annotation but should not trigger the nitpick warning."
  Obligation: literal values remain visible in the annotation output and no
  `pending_xref` is emitted for those value fragments.
  Status: encoded by `PO-001`, `PO-003`, `PO-004`, and `PO-005`.

- `I3` Source: reproduction in `benchmark/PROBLEM.md`.
  Evidence: `typing.Literal[True]` and `typing.Literal[False]`.
  Obligation: qualified `typing.Literal` heads and boolean values are in-domain.
  Status: encoded by `PO-002` and `PO-004`.

- `I4` Source: issue phrase "whatever literal value" plus
  `sphinx.util.typing.stringify()` using `repr()` for `Literal` arguments.
  Obligation: string, numeric, signed numeric, boolean, `None`, ellipsis, dotted
  values, and value representations that appear inside recognized `Literal[...]`
  brackets must not become xrefs.
  Status: encoded by `PO-004` and `PO-005`.

- `I5` Source: existing public parser tests in `repo/tests/test_domain_py.py`.
  Evidence: `int`, `List[int]`, `Tuple[int, int]`, `Callable[[int, int], int]`,
  `List[None]`, and top-level `None` are expected to produce normal Python-domain
  xrefs.
  Obligation: non-Literal type names retain existing xref behavior.
  Status: encoded by `PO-006`.

- `I6` Source: source call-site audit.
  Evidence: all `_parse_annotation()` call sites pass the same two parameters and
  consume a list of nodes.
  Obligation: do not change the function signature, call protocol, or return type.
  Status: encoded by `PO-007`.

## Formal Model

The mini model abstracts docutils nodes to token constructors:

- `XRef(text)` means a Python-domain `pending_xref` for `text`.
- `Text(text)` means visible non-reference text.
- `Punct(text)` means visible signature punctuation.
- `Op(text)` means visible signature operator text.

`Head` is recognized as a Literal head iff it is one of `Literal`,
`typing.Literal`, or `typing_extensions.Literal`. Standalone K-style artifacts
are emitted as `fvk/mini-python-annotation.k` and
`fvk/python-annotation-spec.k`; the excerpt below mirrors their key claims.

K-style core:

```k
module MINI-PY-ANNOTATION-SYNTAX
  syntax Token ::= XRef(String) | Text(String) | Punct(String) | Op(String)
  syntax Tokens ::= List{Token, ","}
  syntax Bool ::= isLiteralHead(String)
  syntax Tokens ::= parseAnn(String) | scan(Tokens, Int, Bool)
endmodule

module MINI-PY-ANNOTATION-SPEC
  imports MINI-PY-ANNOTATION-SYNTAX

  // SPEC-PROVENANCE:
  // - from_prompt: "Literal[True] ... should be present ... should not trigger"
  //   => values inside Literal brackets are Text, not XRef.
  claim <k> parseAnn("typing.Literal[True]") </k>
    => <k> XRef("typing.Literal") Punct("[") Text("True") Punct("]") </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "whatever literal value"
  // - from_code: signed numeric literals parse as UnaryOp, so the sign must stay
  //   in the literal-value path.
  claim <k> parseAnn("Literal[-1]") </k>
    => <k> XRef("Literal") Punct("[") Text("-1") Punct("]") </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_tests: existing parser tests expect normal type names to be xrefs.
  claim <k> parseAnn("List[int]") </k>
    => <k> XRef("List") Punct("[") XRef("int") Punct("]") </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "whatever literal value"
  // - from_code: stringify can produce value text that is not an AST expression.
  claim <k> parseAnn("Literal[<Color.RED: 1>]") </k>
    => <k> XRef("Literal") Punct("[") Text("<Color.RED: 1>") Punct("]") </k>
    [all-path]
endmodule
```

Expected later machine-check commands, not executed here:

```sh
kompile fvk/mini-python-annotation.k --backend haskell
kast --backend haskell fvk/python-annotation-spec.k
kprove fvk/python-annotation-spec.k
```

## Compatibility Audit

No public symbol signature changed. `_parse_annotation(annotation, env)` still
returns `List[Node]`. The internal helpers are nested and private. Existing call
sites require no update.

## Adequacy Audit

The formal claims state that literal values stay visible but are not xrefs, while
ordinary type names still are xrefs. That matches `I1` through `I6`. No claim relies
on the legacy buggy behavior where `True`, `False`, or other values inside
`Literal[...]` become class references.
