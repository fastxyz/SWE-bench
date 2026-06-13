# Code review — V1 fix for sphinx-doc__sphinx-9461

Scope reviewed: the V1 changes to
`sphinx/ext/autodoc/importer.py` (`get_class_members`),
`sphinx/ext/autodoc/__init__.py` (`PropertyDocumenter`),
`sphinx/domains/python.py` (`PyProperty`), plus docs/CHANGES.

Legend: **CONFIRMED** = correct as-is; **CHANGE** = edit made;
**LIMITATION** = deliberately out of scope / documented, no edit.

---

## F1 — Correctness against the reported issue — CONFIRMED
Re-traced the full pipeline for a public classmethod-property
(`@classmethod @property` with a docstring), e.g. `MetaClass.metaclass_class_property`:

1. `get_class_members`: `obj_dict[name]` is a `classmethod` whose `__func__` is a
   `property`; V1 surfaces the **property** as the member value (`class_=subject`).
2. `ClassDocumenter.get_object_members`: kept (default `m.class_ == self.object`).
3. `filter_members`: `getdoc(property)` returns the getter's docstring →
   `has_doc=True` → kept. (Pre-fix, the member value was the getter's *computed*
   value, whose `__doc__` equals `member.__class__.__doc__`, so the docstring was
   nulled and the member silently dropped — the root cause.)
4. Documenter selection: member is a `property` → `PropertyDocumenter`
   (`priority 11`) outranks `AttributeDocumenter` (`priority 10`).
5. `PropertyDocumenter.import_object`: `super()` resolves via `getattr` → computed
   value (not a property) → recovers `parent.__dict__[name].__func__`, sets
   `self.object = property`, `self.isclassmethod = True`.
6. `add_directive_header`: emits `:classmethod:` (and `:abstractmethod:`/`:type:`
   as applicable); `get_doc` reads `property.__doc__`.

Result: the member is documented as `.. py:property::` with `:classmethod:` — the
expected behavior. All six members listed in the issue are own-class members and
follow this path.

## F2 — Root-cause fix must live in member collection — CONFIRMED
`filter_members` runs *before* documenter selection and drops docstring-less
members. Therefore fixing only `PropertyDocumenter` is insufficient — the member
never reaches it. Surfacing the property in `get_class_members` is the minimal
change that addresses the actual root cause. Verified there is no path in
`filter_members` that keeps a docstring-less, non-`INSTANCEATTR`, undocumented
member without `:undoc-members:`.

## F3 — Shared use by autosummary — CONFIRMED (beneficial, no regression)
`sphinx/ext/autosummary/generate.py::get_class_members` calls
`sphinx.ext.autodoc.get_class_members(...)` and reads `member.object`. With V1,
that value is now the `property`, so `autosummary.get_documenter(app, property,
class)` selects `PropertyDocumenter` (objtype `property`) instead of an
attribute/data documenter. This is an improvement for the exact construct in the
issue. Pre-fix the value was the computed result (e.g. a `str`), which also lacked
`__module__`, so the surrounding `imported`/`__module__` checks behave identically
before and after. No autosummary regression.

## F4 — `can_document_member` touches `parent.object` for every non-property member — CONFIRMED safe
The new `else` branch runs for *all* non-property class members and evaluates
`safe_getattr(parent.object, '__dict__', {})`. `Documenter.__init__` sets
`self.object = None`, and `autosummary.get_documenter` constructs a fresh parent
documenter without calling `import_object()`. `getattr(None, '__dict__', {})`
returns `{}`, so `.get(membername)` is `None` and the branch returns `False`. No
`AttributeError`, correct negative result, negligible cost. In the real autodoc
flow `parent.object` is the class (import already ran). Safe in both paths.

## F5 — Private (name-mangled) classmethod-properties are not documented — LIMITATION (no change)
For a private member `__p`, `get_class_members` correctly surfaces the property
(it iterates the mangled `_Cls__p` key in `dir`), so `can_document_member` returns
`True` via `isproperty(member)`. But `import_object` looks up
`self.parent.__dict__.get(<unmangled name>)`, which misses the mangled key
`_Cls__p`, so it returns `False` and the member is silently dropped — an
inconsistency with `can_document_member`. Decision: **do not** expand scope:
- It is **not a regression** — private classmethod-properties were already dropped
  pre-fix (no docstring survived `filter_members`).
- It requires `:private-members:` and is astronomically rare in practice.
- `MethodDocumenter` has the same mangling blind spot (it uses `self.object_name`
  and would lose the `:classmethod:` marker for a private classmethod); the
  codebase does not mangle in these descriptor lookups. Matching that established
  behavior keeps the change minimal and consistent.

## F6 — Inconsistent idiom: `self.objpath[-1]` vs `self.object_name` — CHANGE
`MethodDocumenter.import_object`/`add_directive_header` perform the identical
"raw descriptor from the owner's `__dict__`" lookup using `self.object_name`.
V1's `PropertyDocumenter.import_object` used `self.objpath[-1]`. The two are equal
in the reachable path (`object_name` is set to the last `objpath` element by
`importer.import_object`), so this is a zero-risk consistency fix. Changed to
`self.object_name`.

## F7 — `self.isclassmethod` lifecycle — CONFIRMED safe
Referenced only in `add_directive_header`. `generate()` calls `import_object()`
first and aborts if it returns `False`; every `return True` path of
`import_object` assigns `self.isclassmethod`. Hence it is always defined when
`add_directive_header` runs. No class-level default added — consistent with how
the codebase initializes documenter state inside `import_object`
(`self.object`, `self.analyzer`, etc. are set during the generate flow, not as
class attributes).

## F8 — Abstract classmethod-properties — CONFIRMED for standard usage
For the standard `@classmethod @property @abstractmethod` (abstractmethod
innermost), the recovered `self.object` is the `property`, and
`property.__isabstractmethod__` is `True` (it reflects an abstract `fget`), so
`:abstractmethod:` is emitted. The non-standard reverse order (`@abstractmethod`
*outside* `@classmethod`) would put `__isabstractmethod__` on the `classmethod`
object and would not propagate to the unwrapped property; this is an unusual
construction and not worth special handling.

## F9 — `:type:` annotation — CONFIRMED
`add_directive_header` derives `:type:` from `self.object.fget`'s return
annotation. After recovery `fget` is the underlying getter (`def f(cls) -> T`);
only the return annotation is used, so the `cls`/`self` first parameter is
irrelevant — identical handling to ordinary properties.

## F10 — Directive option ordering — CONFIRMED
Emission order is `:abstractmethod:`, `:classmethod:`, `:type:`. This matches
`PyMethod`'s abstract-before-classmethod ordering and preserves the existing
abstract-property output (`:abstractmethod:` first).

## F11 — `PyProperty` option/prefix — CONFIRMED
`'classmethod'` flag added; no clash with `PyObject.option_spec`
(`noindex/noindexentry/module/canonical/annotation`). `get_signature_prefix`
leaves the existing `abstractmethod` branch untouched (so plain `abstract
property` is unchanged) and appends a `classmethod` branch, yielding
`class property` and `class abstract property`. Short form `class` is consistent
with the directive's pre-existing short form `abstract`.

## F12 — Regression surface for unrelated members — CONFIRMED no regression
- Normal `property`: `obj_dict[name]` is not a `classmethod` → no unwrap;
  `import_object` sees a property → `isclassmethod=False`. Unchanged.
- `cached_property`: not a `classmethod` → no unwrap; `getattr` returns the
  descriptor → treated as property as before.
- Regular `classmethod`/`staticmethod`/function: `isproperty(__func__)` is
  `False` → no unwrap; `MethodDocumenter` still claims them (`isroutine`).
- Plain attributes: untouched.
The new behavior only triggers for `classmethod` objects whose `__func__` is a
property.

## F13 — Python version safety — CONFIRMED
`isproperty` already guards `cached_property` for <3.8. Detection inspects the
class `__dict__` directly, so it is version-independent and harmless on <3.9
(such a member is simply documented as a property).

## F14 — Inherited classmethod-properties with `:inherited-members:` — LIMITATION (no change)
The unwrap keys off the owner's own `__dict__` (`obj_dict`), so a classmethod-
property inherited from a base class is not surfaced and would be dropped by
`filter_members` even with `:inherited-members:`. The reported issue documents
each class's *own* members (each appears under its defining class), so this is out
of scope; an MRO walk would add complexity beyond the issue. Documented, no edit.

## F15 — Docs / CHANGES — CONFIRMED
`:classmethod:` documented on `py:property` with `.. versionadded:: 4.2`
(matches `instance.json` version `4.2` and the CHANGES top section). Two changelog
lines added under "Features added". Classifying support for a new Python-3.9
language construct as a feature (rather than a bug fix) is the conventional choice
here; either is defensible and it is not test-relevant.
