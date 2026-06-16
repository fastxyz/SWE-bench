# FORMAL_SPEC_ENGLISH.md

Status: paraphrase of `fvk/modelform-callback-spec.k`.

1. `META-DIRECT`: If a form class has no top-level callback override and the
   resolved inner `Meta` object contains `cbMeta`, callback resolution returns
   `cbMeta`.
2. `TOP-LEVEL-OVERRIDE`: If a form class has a top-level callback override
   `cbTop`, callback resolution returns `cbTop` even when `Meta` contains
   `cbMeta`.
3. `TOP-LEVEL-NONE-DISABLES`: If a form class explicitly provides a top-level
   callback value of `None`, callback resolution returns `None`; the `Meta`
   callback is not used.
4. `FACTORY-OMITTED-PRESERVES-META`: If `modelform_factory()` is called with
   the default `None` callback argument and the base form's `Meta` provides
   `cbMeta`, the generated class resolves to `cbMeta`.
5. `FACTORY-EXPLICIT-OVERRIDES-META`: If `modelform_factory()` is called with
   explicit `cbFactory`, the generated class resolves to `cbFactory` even when
   the base form's `Meta` provides `cbMeta`.
6. `FACTORY-FALSEY-NON-NONE-OVERRIDES`: If `modelform_factory()` is called with
   a falsey but non-`None` callback object, the generated class resolves to
   that object.
7. `INHERITED-META-PRESERVES`: If a subclass has no replacement `Meta`, the
   resolved parent `Meta` callback is preserved.
8. `REPLACED-META-DOES-NOT-LEAK-BASE`: If a subclass replaces `Meta` and the
   replacement has no callback, the base form's callback is not used by a
   special fallback.
