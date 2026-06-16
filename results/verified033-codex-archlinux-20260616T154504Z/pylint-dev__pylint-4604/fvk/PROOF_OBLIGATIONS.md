# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO1: Direct attribute annotations collect their imported base

For any annotation represented as `Attr(Name(BASE), FIELD)`, collected
annotation names must contain `BASE`.

Concrete public instance: `abc.ABC` collects `abc`.

K claim: `ATTR-ABC-NAMES`.

Finding links: F1.

## PO2: Existing supported annotation shapes keep working

`Name(N)` must collect `N`. `Sub(VALUE, ARGS)` must collect names from `VALUE`
and every annotation in `ARGS`. Fully qualified `typing.*` annotations must
still collect `typing`.

Concrete public instances: `ABC`, `List[Any]`, `typing.Optional[str]`, function
type comments in existing fixtures.

K claims: `NAME-ABC`, `TYPING-NESTED-ABC`.

Finding links: F2, F4.

## PO3: Type-used imports are suppressed by the existing predicate

Given collected names `NAMES`, `_check_imports` must suppress `unused-import`
for an import candidate when `imported_name in NAMES` or `as_name in NAMES`.

Concrete public instances: `import abc` with `abc.ABC`, and `from abc import
ABC` with `ABC`.

K claims: `REPRO-ABC`, `SUPPRESS-IMPORT`.

Finding links: F1, F4.

## PO4: Dotted attribute chains collect dotted prefixes

For `Attr(Attr(Name(A), B), C)`, collected names must include `A` and `A.B`.
This aligns the annotation collector with `_fix_dot_imports`, which can pass
dotted import keys to `_check_imports`.

Concrete instance: `xml.etree.ElementTree` collects `xml.etree`.

K claim: `DOTTED-IMPORT`.

Finding links: F3.

## PO5: Unmatched imports are not newly suppressed

If neither the imported name nor the alias is in collected annotation names,
this change must not suppress `unused-import`. Other existing filters in
`_check_imports` are outside this proof slice and remain framed.

K claim: `UNMATCHED-IMPORT-FRAME`.

Finding links: F5.

## Machine-check Commands Not Run

The commands to machine-check the constructed proof later are:

```sh
kompile fvk/mini-pylint-variables.k --backend haskell
kast --backend haskell fvk/type-annotation-import-spec.k
kprove fvk/type-annotation-import-spec.k --definition fvk/mini-pylint-variables-kompiled
```

Expected result after a successful machine check: `#Top` for all claims.
