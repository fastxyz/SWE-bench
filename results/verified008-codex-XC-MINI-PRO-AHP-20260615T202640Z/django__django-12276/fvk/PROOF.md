# Constructed Proof

Status: constructed, not machine-checked.

## Theorem

For the modeled render-attribute decision, V2 satisfies the public intent:

- plain `FileInput` suppresses `required` when a truthy initial file value
  exists;
- plain `FileInput` still allows `required` when no initial value exists and the
  field/form gates allow it;
- `ClearableFileInput` and `AdminFileWidget` preserve compatible inherited
  behavior;
- field-level, form-level, and hidden-widget gates remain in force.

## Symbolic Proof Sketch

The mini semantics rewrites:

```text
buildRequiredAttr(W, I, FieldRequired, FormUseRequired)
=> FieldRequired andBool FormUseRequired andBool useRequiredAttribute(W, I)
```

For `FileInput`, the V2 source rule is modeled as:

```text
useRequiredAttribute(FileInput, I)
=> baseUseRequiredAttribute(FileInput) andBool notBool hasInitial(I)
=> true andBool notBool hasInitial(I)
```

Case `I = initial`:

```text
hasInitial(initial) => true
buildRequiredAttr(FileInput, initial, true, true)
=> true andBool true andBool (true andBool notBool true)
=> false
```

Case `I = noInitial`:

```text
hasInitial(noInitial) => false
buildRequiredAttr(FileInput, noInitial, true, true)
=> true andBool true andBool (true andBool notBool false)
=> true
```

Field/form gate cases reduce by boolean conjunction:

```text
buildRequiredAttr(FileInput, initial, false, true) => false
buildRequiredAttr(FileInput, initial, true, false) => false
```

`ClearableFileInput` and `AdminFileWidget` rewrite through inherited dispatch:

```text
useRequiredAttribute(ClearableFileInput, I) => useRequiredAttribute(FileInput, I)
useRequiredAttribute(AdminFileWidget, I) => useRequiredAttribute(FileInput, I)
```

Thus their initial-data claims reduce to the proven `FileInput` cases.

## Adequacy Gate

`INTENT_SPEC.md`, `FORMAL_SPEC_ENGLISH.md`, `SPEC_AUDIT.md`, and
`PUBLIC_COMPATIBILITY_AUDIT.md` are present and non-empty. `SPEC_AUDIT.md`
marks all formal claims as passing against public intent. No proof obligation
depends only on legacy behavior.

## Machine-Check Commands

These commands were written into the artifacts but not executed:

```sh
cd fvk
kompile mini-django-fileinput.k --backend haskell
kast --backend haskell fileinput-required-spec.k
kprove fileinput-required-spec.k
```

Expected result after later machine-checking: `#Top`.

## Test Guidance

No test files were modified. If this were a normal development pass, useful
tests would cover:

- rendering `FileField(widget=FileInput)` without initial data includes
  `required`;
- rendering `FileField(widget=FileInput)` with a truthy `ContentFile` initial
  omits `required`;
- `ClearableFileInput.use_required_attribute()` keeps its initial/no-initial
  behavior through inheritance.

Any removal of tests covered by the proof should remain conditional on actually
running `kprove` and receiving `#Top`.
