# Baseline notes — sphinx-doc__sphinx-9229

## Issue

> Inconsistent behaviour with type alias documentation (not overwriting all the
> default messages, just some)

The reporter has three module-level type aliases, each documented with a
next-line `"""..."""` docstring:

```python
ScaffoldOpts = Dict[str, Any]
"""..."""
FileContents = Union[str, None]
"""..."""
FileOp = Callable[[Path, FileContents, ScaffoldOpts], Union[Path, None]]
"""..."""
```

For **one** of them the docstring renders; for the other **two** only the
auto-generated `alias of ...` text shows and the docstring is dropped.

## Root cause

`ClassDocumenter.get_doc()` (in `sphinx/ext/autodoc/__init__.py`) returned
`None` unconditionally whenever `self.doc_as_attr` is `True` — i.e. whenever the
documented name is an *alias* of a class (`Alias = Foo`):

```python
def get_doc(self, ignore=None):
    if self.doc_as_attr:
        # Don't show the docstring of the class when it is an alias.
        return None
    ...
```

The intent ("don't show the *aliased class's* `__doc__`") is correct, but the
code also discarded the **alias variable's own documentation comment** (the
`#:` comment before, or the next-line `"""..."""` docstring after the
assignment).

Whether the comment is still displayed then depends on the base
`Documenter.add_content()` "analyzer path", which looks the comment up in
`self.analyzer.attr_docs`. But `self.analyzer` is built from
`self.real_modname`, which for a class alias resolves to the *aliased class's*
module (`self.object.__module__`) when the documenter is invoked directly
(`autoclass` directive / `do_autodoc`). When the aliased class lives in a
**different module** than the alias, the analyzer points at the wrong module,
the comment is not found there, and — because `get_doc()` returns `None` — the
comment is dropped entirely, leaving only `alias of ...`.

This explains the reporter's "1 works, 2 don't" exactly. On their Python 3.6:

- `Dict[str, Any]` and `Callable[...]` are `typing.GenericMeta` /
  `CallableMeta` instances, which **are** subclasses of `type`, so
  `ClassDocumenter.can_document_member()` claimed them and treated them as class
  aliases (`__module__ == 'typing'`, i.e. an external module) → docstring lost.
- `Union[str, None]` is **not** a `type`, so it was handled by
  `DataDocumenter`, whose `get_doc()` reads the variable comment via
  `get_module_comment()` → docstring kept.

The same bug affects any alias of a class defined in another module / a builtin
(e.g. `IntAlias = int`) on every Python version.

## Change

File: `sphinx/ext/autodoc/__init__.py` — `ClassDocumenter`

1. Added `get_variable_comment()`, mirroring `DataDocumenter.get_module_comment`
   / `AttributeDocumenter.get_attribute_comment`. It reads the alias variable's
   own doc-comment from the module where the alias is **defined**
   (`self.modname`), using the proper `attr_docs` key
   `('.'.join(self.objpath[:-1]), self.objpath[-1])` (works for both
   module-level and class-level aliases).

2. Changed `get_doc()` so that, for `doc_as_attr`, it returns the variable
   comment (`[comment]`) when one exists and `None` otherwise.

```python
def get_variable_comment(self):
    try:
        key = ('.'.join(self.objpath[:-1]), self.objpath[-1])
        analyzer = ModuleAnalyzer.for_module(self.modname)
        analyzer.analyze()
        return list(analyzer.attr_docs.get(key, []))
    except PycodeError:
        return []

def get_doc(self, ignore=None):
    if self.doc_as_attr:
        # Don't show the docstring of the class when it is an alias.
        comment = self.get_variable_comment()
        if comment:
            return [comment]
        else:
            return None
    ...
```

File: `CHANGES` — added a "Bugs fixed" entry under 4.1.0 referencing #9229.

### Why this is correct and side-effect free

- **No duplication.** The base `add_content()` analyzer path sets
  `no_docstring=True` when *it* finds the comment, which short-circuits the
  `get_doc()` call. So when the analyzer points at the right module (e.g. via
  `automodule`, where `real_modname` is forced to the documented module) the
  comment is shown by that path and `get_doc()` is not called; when it points at
  the wrong module (direct documentation of an external alias) `get_doc()`
  supplies it. The two paths are mutually exclusive.
- **Comment-less aliases are unchanged.** For `Alias = Foo` with no comment,
  `get_variable_comment()` returns `[]`, so `get_doc()` still returns `None`,
  `process_doc()` is not invoked, and the `autodoc-process-docstring` event is
  not emitted — keeping `test_class_alias` (which connects a handler that raises
  to assert it is never called) green. Existing alias tests that expect only
  `alias of ...` (`test_autodoc_inner_class` `Outer.factory`,
  `test_autodoc_typed_instance_variables` `Alias`) are likewise unaffected.

## Assumptions and rejected alternatives

- **Use `self.modname`, not `get_real_modname()`.** The variable comment lives
  in the source file where the alias is assigned (`self.modname`), not in the
  aliased class's module (`get_real_modname()`/`self.object.__module__`). Using
  `get_real_modname()` would still fail for external aliases and would raise
  `PycodeError` for builtins/C modules.
- **Rejected: suppress `alias of ...` when a docstring exists.** Existing tests
  (`test_autodata_GenericAlias`, `test_autodata_NewType`, …) deliberately show
  *both* the docstring and the `alias of ...` line, so the intended behaviour is
  to show both consistently — not to have the docstring replace it.
- **Rejected: fix the analyzer / `real_modname` so the base analyzer path always
  finds the comment.** More invasive and affects attribute-doc discovery for all
  class documentation; mirroring the existing `get_*_comment` + `get_doc`
  pattern is targeted and idiomatic.
- **Rejected: return `[]` from `get_doc()` for aliases with a comment.**
  Returning `[]` makes the base `add_content()` process an empty dummy docstring
  and add nothing, so the comment would still not appear for external aliases
  (where the analyzer path does not find it). The comment content must actually
  be returned (`[comment]`).
