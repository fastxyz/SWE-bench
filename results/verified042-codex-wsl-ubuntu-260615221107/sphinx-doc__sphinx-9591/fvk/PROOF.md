# Constructed Proof

Constructed, not machine-checked.

## Claims Proved

1. `PROPERTY-TYPE-XREF`: a non-empty property `:type:` option `T` appends a
   signature annotation containing visible text `": "` and an `xref(T)` node.
2. `PROPERTY-NO-TYPE-FRAME`: absent a `:type:` option, the type-handling
   fragment leaves the signature node list unchanged.
3. Prose frame obligations: V1 preserves the base signature handling return
   tuple, public method signature, directive registration, and autodoc producer
   behavior.

## Symbolic Proof Sketch

For `PROPERTY-TYPE-XREF`, begin with:

```k
<k> handlePropertyType(type(T)) </k>
<signode> S </signode>
requires T =/=String ""
```

The semantics rule for `handlePropertyType(type(T))` rewrites the computation to
`parseAnnotation(T) ~> appendPropertyType`. The `parseAnnotation(T)` rule
rewrites to `xref(T)` for non-empty `T`, modeling `_parse_annotation()` producing
a Python reference node for a type token. The final rule consumes that node and
updates the framed signature list from `S` to
`S descAnn(.Nodes txt(": ") xref(T))`, then terminates at `.K`. By transitivity,
the initial state reaches the claimed post-state.

For `PROPERTY-NO-TYPE-FRAME`, the `handlePropertyType(noType)` rule rewrites
directly to `.K` and leaves `<signode> S </signode>` untouched. This establishes
the no-type frame condition.

The source proof aligns with the K model:

- `PyProperty.handle_signature()` obtains `fullname, prefix` from
  `super().handle_signature(...)` before type handling and returns the same
  tuple after type handling.
- The `if typ:` branch calls `_parse_annotation(typ, self.env)`.
- The append operation uses `nodes.Text(': ')` followed by the parsed annotation
  nodes, matching the modeled `txt(": ") xref(T)` suffix.
- `PropertyDocumenter` already emits `:type:` from property getter return
  annotations, so no producer-side transition is required.

## Rejected Pre-Fix Proof

The pre-fix transition would append `descAnn(txt(": " + T))` or equivalent
plain text. That state cannot satisfy `PROPERTY-TYPE-XREF`, because the model
distinguishes plain text from `xref(T)`. This is the formal reason the legacy
behavior is a bug rather than a frame condition.

## Adequacy And Compatibility

The English paraphrase in `FORMAL_SPEC_ENGLISH.md` matches the public intent in
`INTENT_SPEC.md`; `SPEC_AUDIT.md` marks each obligation as pass. The public
compatibility audit found no method signature, option schema, return shape,
registration, producer, or subclass/override blocker.

## Machine-Check Commands

These commands were not run:

```sh
kompile fvk/mini-python-domain.k --backend haskell
kast --backend haskell fvk/python-property-spec.k
kprove fvk/python-property-spec.k --definition fvk/mini-python-domain-kompiled
```

Expected result after a successful future machine check: `#Top` for the claims
in `fvk/python-property-spec.k`.

## Test Recommendation

No test files were modified. A focused test that inspects the doctree for
`py:property` with `:type: Point` should be kept or added until the K proof is
machine-checked. Any existing test that only asserts the visible text
`": Point"` without checking pending xref structure is not sufficient for this
issue, because it cannot distinguish the pre-fix failure from V1.
