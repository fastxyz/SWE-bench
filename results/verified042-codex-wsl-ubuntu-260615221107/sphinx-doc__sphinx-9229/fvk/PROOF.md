# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Adequacy Gate

The public intent is that source docstrings for all type aliases render instead
of generated `alias of ...` fallback text. The K claims state exactly that for
the three content-producing routes under audit:

- data aliases;
- class attributes that are aliases;
- `ClassDocumenter.doc_as_attr` aliases.

The claims also preserve fallback text for undocumented aliases and require
dependency recording when the class-alias route reads a source analyzer.

## Proof Sketch

### Data Alias Route

Case split on `HasDocComment`.

- `HasDocComment = true`: `DataDocumenter.get_doc()` returns the source comment.
  `GenericAliasMixin`, `NewTypeMixin`, and `TypeVarMixin` each guard fallback
  generation with `not self.has_docstring_comment()`. The guard is false, so
  `update_content()` contributes no fallback. The observable is
  `result(true, false, false)`.
- `HasDocComment = false`: no source comment is returned. For alias kinds with
  existing fallback support, the guard is true and fallback text is appended.
  The observable is `result(false, true, false)`.

This discharges PO2 and the data claims.

### Attribute Alias Route

The same case split applies. `AttributeDocumenter.has_docstring_comment()` uses
the class-scope analyzer lookup. If true, `get_doc()` returns the source comment
and the mixin fallback guards are false. If false, legacy fallback generation is
preserved. This discharges PO3 and the attribute claims.

### Class Alias Route

Case split on `HasDocComment`.

- `HasDocComment = true`: `ClassDocumenter.get_docstring_comment()` finds the
  aliasing scope key in `attr_docs`, records `analyzer.srcname`, and returns the
  comment. `get_doc()` returns that comment for `doc_as_attr`, and `add_content()`
  does not replace content with `alias of ...` because the comment lookup is not
  `None`. The observable is `result(true, false, true)`.
- `HasDocComment = false`: `get_doc()` returns `None` for `doc_as_attr`, and
  `add_content()` keeps the legacy generated fallback. The observable is
  `result(false, true, false)`.

This discharges PO4 and PO5.

## Compatibility Proof

No public method signatures, directive option names, event names, or return
types are changed. The fix adds helper methods and narrows fallback generation
under the intent-derived `has_docstring_comment()` predicate. Undocumented alias
fallback behavior is preserved by explicit claims.

## Residual Risk

This is a partial-correctness proof over a focused mini semantics. It does not
prove termination, full Python semantics, custom extension event behavior, or
manual directive body behavior. Test removal is not recommended without a real
machine check returning `#Top`.
