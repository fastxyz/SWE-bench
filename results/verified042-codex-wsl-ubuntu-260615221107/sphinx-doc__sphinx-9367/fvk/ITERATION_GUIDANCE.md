# FVK ITERATION GUIDANCE

Status: V2 source change applied; proof constructed, not machine-checked.

## Code Guidance

Keep the V1 direct tuple fix. Finding F-001 and obligations PO-1/PO-2 require
the explicit `len(node.elts) == 1` branch in `visit_Tuple()`.

Keep the V2 subscript helper fix. Finding F-002 and obligations PO-3/PO-4 show
that V1 did not cover the separate simple tuple-slice formatter in
`visit_Subscript()`.

Do not change public signatures or test files. Finding F-003 and PO-5 show the
desired repair is local to string construction, and the benchmark forbids test
edits.

## Verification Guidance

When an execution environment with K exists, run:

```sh
cd fvk
kompile mini-pycode-unparse.k --backend haskell
kast --backend haskell pycode-ast-tuple-spec.k
kprove pycode-ast-tuple-spec.k
```

Treat the expected `#Top` as unconfirmed until those commands are actually run.

## Test Guidance

Do not edit tests in this benchmark. For a normal development follow-up, add
coverage for:

- direct one-element tuple expression: `("(1,)", "(1,)")`;
- one-element tuple slice in subscript: `("obj[1,]", "obj[1,]")`;
- regression frame cases already represented publicly, such as `()` and
  `Tuple[int, int]`.

After a real machine check returns `#Top`, in-domain point tests covered by the
claims may be considered redundant, but test deletion should remain a separate
human decision.

## Remaining Questions

No user clarification is needed for the reported issue. The public intent is
specific about preserving the one-element tuple comma. The only broader question
is whether the project wants a larger audit of other independent AST renderers,
such as `sphinx.domains.python._parse_annotation()`, which is outside this issue
because it produces docutils nodes rather than `pycode.ast.unparse()` strings.
