# FVK Proof

Status: constructed, not machine-checked. No commands were executed.

## What Is Proved

Within the mini Pylint variables model, if an import is referenced by a parsed
type comment as a simple name, an attribute base, a dotted attribute prefix, or a
nested subscript member, then the collected type-annotation name set contains a
key that `_check_imports` compares against. Therefore the type-annotation branch
suppresses `unused-import` for that import.

The proof is partial-correctness only. There are no loops or recursion in the
modeled helper slice, so no loop circularities are required.

## Symbolic Proof Sketch

### `ATTR-ABC-NAMES`

Start state: `collect(Attr(Name("abc"), "ABC"))`.

By the `collect-attr` rule, collection is the union of names from the base and
qualified prefixes from the attribute chain.

By `collect-name`, the base contributes `"abc"`.

By `qnames-attr-name`, the attribute chain contributes `"abc"` and `"abc.ABC"`.

By set union, the result contains `"abc"` and `"abc.ABC"`.

### `REPRO-ABC`

Start state: `isTypeUsed("abc", noAlias, collect(Attr(Name("abc"), "ABC")))`.

From `ATTR-ABC-NAMES`, `"abc"` is in the collected set.

By the `type-used-imported` rule, `isTypeUsed` rewrites to `true`.

By the modeled `_check_imports` branch, `true` means the checker takes the
continue path before adding `unused-import`.

### `NAME-ABC`

Start state: `collect(Name("ABC"))`.

By `collect-name`, the result is the singleton set containing `"ABC"`.

For `from abc import ABC`, `_check_imports` compares `imported_name == "ABC"`,
so `type-used-imported` applies.

### `TYPING-NESTED-ABC`

Start state:
`collect(Sub(Attr(Name("typing"), "Optional"), Attr(Name("abc"), "ABC")))`.

By `collect-sub`, collection unions the subscript value and argument
collections.

The value side contributes `"typing"` by the same attribute reasoning as
`ATTR-ABC-NAMES`.

The argument side contributes `"abc"` and `"abc.ABC"`.

Therefore both `import typing` and `import abc` are type-used. This is the
proof-derived reason V1's early `return` in the `typing` branch was too strong.

### `DOTTED-IMPORT`

Start state:
`collect(Attr(Attr(Name("xml"), "etree"), "ElementTree"))`.

By repeated `qnames-attr-attr`, the attribute chain prefixes are:

- `"xml"`
- `"xml.etree"`
- `"xml.etree.ElementTree"`

Therefore an import candidate with `imported_name == "xml.etree"` is type-used.
This aligns with `_fix_dot_imports`, which can expand the unconsumed local root
to the dotted imported module name.

### `SUPPRESS-IMPORT`

For arbitrary `IMPORTED`, `ALIAS`, and `NAMES`, the modeled predicate is:

`isTypeUsed(IMPORTED, ALIAS, NAMES) = IMPORTED in NAMES or ALIAS in NAMES`.

This is exactly the production predicate:

```python
is_type_annotation_import = (
    imported_name in self._type_annotation_names
    or as_name in self._type_annotation_names
)
```

When the predicate is true, production code continues before `add_message` is
called in both import branches.

### `UNMATCHED-IMPORT-FRAME`

If `IMPORTED` and `ALIAS` are absent from `NAMES`, the modeled
`isTypeUsed` predicate rewrites to `false`. The model then leaves the candidate
to the existing checker branches. This proves the fix does not create a blanket
suppression for unrelated imports.

## Residual Risk

The model abstracts astroid traversal to algebraic nodes and treats
`_type_annotation_names` as a set. This is adequate for the audited property
because `_check_imports` observes only membership.

The proof does not cover stringized annotations, import inference, message
formatting, package `__init__` policy, or other `VariablesChecker` messages.
Those are outside the issue's type-comment import intent.

## Machine-check Commands Not Run

```sh
kompile fvk/mini-pylint-variables.k --backend haskell
kast --backend haskell fvk/type-annotation-import-spec.k
kprove fvk/type-annotation-import-spec.k --definition fvk/mini-pylint-variables-kompiled
```

Expected successful machine-check result: `#Top`.

## Test Guidance

No tests were modified. Regression tests for the concrete repro should be kept
until the proof is machine-checked. Useful public regression cases are:

- `import abc`; `# type: abc.ABC`
- `from abc import ABC`; `# type: ABC`
- `import abc, typing`; `# type: typing.Optional[abc.ABC]`
- `import xml.etree`; `# type: xml.etree.ElementTree`
