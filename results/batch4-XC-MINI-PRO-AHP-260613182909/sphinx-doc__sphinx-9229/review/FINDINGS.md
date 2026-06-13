# Code review — V1 fix for sphinx-doc__sphinx-9229

V1 changed `ClassDocumenter` in `sphinx/ext/autodoc/__init__.py`: it added
`get_variable_comment()` and made `get_doc()`, in the `doc_as_attr` (class
alias) branch, return that variable comment instead of unconditionally `None`.
A `CHANGES` entry was added.

Scope of review: correctness vs. the issue, edge/boundary cases, error handling,
interactions/regressions with surrounding code, and consistency with codebase
conventions. No execution available; all reasoning is static.

---

## F1 — Correctness against the issue (CONFIRMED correct)

Root cause is correctly identified: `ClassDocumenter.get_doc()` returned `None`
whenever `self.doc_as_attr` is `True`, discarding the alias variable's *own*
documentation comment (the `#:` comment or next-line `"""…"""`). The base
`Documenter.add_content()` "analyzer path" could only recover it when
`self.analyzer` (built from `self.real_modname`) happens to point at the module
that defines the alias; for an alias whose target lives in another module
(`__module__ != self.modname`), the analyzer points elsewhere and the comment is
lost — leaving only `alias of …`.

Traced against the reporter's three aliases on Python 3.6 (their environment):
`Dict[str, Any]` and `Callable[...]` are `typing.GenericMeta`/`CallableMeta`
instances, i.e. subclasses of `type`, so they are claimed by `ClassDocumenter`
with `__module__ == 'typing'` (a *different* module) → comment dropped;
`Union[str, None]` is **not** a `type`, so it is handled by `DataDocumenter`
(whose `get_doc` reads the comment via `get_module_comment`) → comment kept.
This exactly reproduces "1 of 3 works". V1 makes the two `ClassDocumenter` cases
behave like the `DataDocumenter` case. Correct.

## F2 — Module used for the lookup: `self.modname` (CONFIRMED correct)

The alias's comment is in the source file where the alias is *assigned* =
`self.modname`. `self.get_real_modname()` / `self.object.__module__` is the
*aliased class's* module, which is exactly the module that fails for external
aliases (and raises `PycodeError` for C/builtin targets such as `int`). Using
`self.modname` is therefore required and correct; it also coincides with the
forced `real_modname` in the `automodule` path, so it never disagrees there.

## F3 — attr_docs key format (CONFIRMED correct)

`('.'.join(self.objpath[:-1]), self.objpath[-1])` matches the parser's
`(namespace, name)` keys for both module-level aliases `('', name)` and
class-level aliases `(ClassQualname, name)` (`VariableCommentPicker.
add_variable_comment` uses `".".join(qualname[:-1])` as the namespace). It is
strictly more general than `('', '.'.join(self.objpath))`, which would be wrong
for class-level aliases (`('', 'Foo.Alias')` vs. the actual `('Foo', 'Alias')`).

## F4 — No double rendering with the analyzer path (CONFIRMED)

In `Documenter.add_content`, when the analyzer path finds the key it sets
`no_docstring = True`, and the subsequent docstring block runs only
`if not no_docstring:`. So the analyzer path (correct-module analyzer:
`automodule`, same-module direct) and `get_doc()` (wrong-module analyzer:
external direct) are mutually exclusive — the comment is rendered exactly once
in every path. No duplication.

## F5 — Cache safety (CONFIRMED)

`get_variable_comment` returns `list(...)`, i.e. a *copy* of the cached
`ModuleAnalyzer.attr_docs[key]`. This matters because `Documenter.process_doc`
mutates the docstring list in place (`docstringlines.append('')`). Returning the
cached list directly would corrupt the shared analyzer cache. V1 copies, exactly
like `get_module_comment` / `get_attribute_comment` and the analyzer path.

## F6 — No regression for comment-less aliases (CONFIRMED)

With no comment, `get_variable_comment` is falsy → `get_doc` returns `None` →
`process_doc` is not called and `autodoc-process-docstring` is not emitted.
`test_class_alias` (`Alias = Foo`, no comment, with a handler that raises to
assert it is never called for aliases) stays green. Existing alias expectations
that show only `alias of …` — `test_autodoc_inner_class` (`Outer.factory = dict`,
documented with a plain `#` comment, not `#:`), `test_autodoc_typed_instance_
variables` (`Alias = Derived`, no comment) — are unaffected because those
aliases have no extracted doc-comment.

## F7 — No regression for ordinary classes (CONFIRMED)

For a real class, `doc_as_attr` is `False`, so the new branch is not entered and
class docstring handling (including `_new_docstrings`, `class-doc-from`,
`__init__`/`__new__` docstrings) is untouched.

## F8 — Intended behavior change: event now fires for documented aliases (OK)

For an external alias *with* a comment, V1 now emits `autodoc-process-docstring`
(previously it never fired because only `alias of …` was produced). This is the
correct, desired behavior (the user's docstring should be processed), and no
test asserts the old buggy behavior. It is also consistent with what already
happens for same-module aliases via the analyzer path.

## F9 — Error handling and boundary conditions (CONFIRMED, with one note)

- Only `PycodeError` is caught — consistent with `get_module_comment`.
  `ModuleAnalyzer.for_module` and `analyze()` only raise `PycodeError`.
- `self.objpath` is guaranteed non-empty whenever `doc_as_attr` is `True`:
  `import_object` evaluates `self.objpath[-1] != self.object.__name__` to set
  `doc_as_attr`, so reaching `get_doc` with `doc_as_attr` implies a non-empty
  `objpath`. Hence `self.objpath[-1]` / `self.objpath[:-1]` cannot `IndexError`.
- Empty-but-present comment (`attr_docs[key] == ['']`) yields one blank content
  line; this is rare (an empty `#:`/`""""""`) and is identical to what the
  analyzer path already produces, so no new inconsistency.

## F10 — Convention inconsistency in `get_variable_comment` (MINOR — fix)

The two direct analogs, `DataDocumenter.get_module_comment` and
`AttributeDocumenter.get_attribute_comment`, both use
`if key in analyzer.attr_docs: return list(...)` and `return None` on
miss/`PycodeError`. V1 instead uses `analyzer.attr_docs.get(key, [])` and
`return []`. Functionally identical at the only call site (`if comment:` treats
`None` and `[]` alike), but it diverges from the sibling pattern and makes the
`Optional[List[str]]` return annotation inaccurate (it never returns `None`).
Recommend aligning to the sibling structure. Pure consistency; no behavior
change.

## F11 — Interaction with `DocstringSignatureMixin` (CONFIRMED safe)

`ClassDocumenter.format_signature` returns `''` immediately for `doc_as_attr`,
so `_find_signature` never runs and `_new_docstrings` stays `None`. The
`doc_as_attr` branch in `get_doc` is checked *before* the `_new_docstrings`
lookup, so there is no interference between the new branch and signature
extraction.

## F12 — Rendering/indentation (CONFIRMED)

`add_content` runs after `self.indent += self.content_indent`, so the returned
comment lines are emitted at the correct indentation under the generated
`.. py:attribute:: <name>` directive, matching the existing alias output format
(`test_class_alias`).

---

## Verdict

V1 is correct and free of regressions (F1–F9, F11–F12). The only actionable item
is the cosmetic convention mismatch in `get_variable_comment` (F10), which is
worth aligning with its sibling methods. Apply that single, behavior-preserving
refactor; otherwise the fix stands.
