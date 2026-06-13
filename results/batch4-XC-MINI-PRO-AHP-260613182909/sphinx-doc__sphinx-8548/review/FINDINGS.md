# Code review — V1 fix for sphinx-doc__sphinx-8548

V1 changed two files:
- `sphinx/ext/autodoc/importer.py` — added `PycodeError` import; rewrote the
  trailing analyzer block of `get_class_members()` to walk the MRO and
  add/complete comment docstrings from base classes.
- `sphinx/ext/autodoc/__init__.py` — `AttributeDocumenter.get_doc()` now first
  consults `get_attribute_comment(self.parent)` (an MRO-walking helper inherited
  from `UninitializedInstanceAttributeMixin`).

The review traced the full autodoc flow for the issue's example and related
cases. Findings are numbered; each states a verdict.

## Correctness against the issue

**F1 — Primary case (inherited class-level data attribute) is fixed. VERIFIED.**
For `class Inherited(Base)` where `Base` has `#: A base attribute.\n ham = True`:
`get_class_members(Inherited, ...)` discovers `ham` via `dir()` with
`class_=None, docstring=None`, and the new MRO analyzer loop, when it reaches
`Base` (`qualname == 'Base'`), matches `('Base','ham')` in `Base`'s module
analyzer and fills `members['ham'].docstring`. `filter_members` then sees
`ObjectMember.docstring` truthy → `has_doc=True` → keeps `ham` (it was dropped as
undocumented before). The per-attribute `AttributeDocumenter` for
`Inherited.ham` has `self.object == True` (a real value, **not**
`UNINITIALIZED_ATTR`), so `add_content` → `get_doc()` and the new comment check
returns `['A base attribute.', '']`.

**F2 — `get_doc` change is the necessary piece for the class-level case.
VERIFIED.** Before V1, for a real-valued inherited attribute,
`UninitializedInstanceAttributeMixin.get_doc` only returned the comment when
`self.object is UNINITIALIZED_ATTR`; for `ham == True` it fell through to
`NonDataDescriptorMixin.get_doc`, which returns `[]` for non-descriptors. So the
comment would not be shown without the new check at the top of
`AttributeDocumenter.get_doc`. Both V1 edits are therefore required; neither is
redundant for the reported example.

**F3 — Inherited *instance* attributes (issue #6415, mentioned in the thread)
also work now. VERIFIED, bonus.** `self.ham = True  #: ...` in `Base.__init__`
is keyed `('Base','ham')`. The MRO loop adds it as a new member
`ClassAttribute(Base, 'ham', INSTANCEATTR, doc)`. At documenting time
`import_object` resolves it to `UNINITIALIZED_ATTR` via
`is_uninitialized_instance_attribute` (which uses the MRO-searching
`get_attribute_comment`), and the comment is rendered.

**F4 — `autoattribute` on an inherited attribute works. VERIFIED.** A direct
`.. autoattribute:: pkg.Inherited.ham` goes straight to `AttributeDocumenter`;
`get_doc` → `get_attribute_comment` finds the base-class comment.

**F5 — Non-`:inherited-members:` behavior preserved. VERIFIED.**
`ClassDocumenter.get_object_members` else-branch keeps only `m.class_ ==
self.object`. An inherited class attribute keeps `class_=None` (set by the
`dir()` loop; V1 only fills `.docstring`), and an inherited instance attribute
gets `class_=base`; both compare unequal to the subject, so they remain excluded
unless `:inherited-members:` is given. No over-inclusion.

## Edge cases / boundary conditions

**F6 — `attr_docs` key format matches `__qualname__`. VERIFIED.** In
`sphinx/pycode/parser.py`, comment keys are `(".".join(qualname[:-1]), name)`,
where `qualname` is built from the class/function nesting context. For a
top-level class this is the class name; for nested classes it is the dotted
path — exactly `cls.__qualname__`. So comparing `ns == cls.__qualname__` is
correct and strictly more correct than the old `'.'.join(objpath)` (which is
only available for the subject, not its bases). Classes defined inside functions
(`<locals>`) won't match, but that is a pre-existing limitation shared by the old
code and `get_attribute_comment`; autodoc cannot address such classes anyway.

**F7 — MRO ordering / override precedence is correct. VERIFIED.** The MRO loop
iterates most-derived first and only fills a member's docstring when it is still
`None` (`elif members[name].docstring is None`), so a subclass that re-documents
an attribute wins over a base class. A subclass that overrides only the *value*
(no new comment) correctly inherits the base comment, matching method-docstring
inheritance semantics.

**F8 — Private inherited members are not over-exposed. VERIFIED.** A documented
private inherited attribute (`self._x  #: ...`) is added with a docstring, but
`filter_members`' `want_all and isprivate` branch still gates it on
`private_members`, so it stays hidden unless `:private-members:` is set.

**F9 — Annotation-only inherited attributes unaffected/handled. VERIFIED.** The
pre-existing annotation loop already added them MRO-wide with `class_=cls`; the
new loop only attaches a docstring if a comment exists. With no comment and no
value they remain undocumented (dropped unless `:undoc-members:`), consistent
with non-inherited behavior; the `:type:` is still emitted via
`get_type_hints`/`update_annotations`.

**F10 — Empty `#:` comment: minor inconsistency, not a regression. NOTED, not
fixed.** For a *local* attribute, `filter_members` keeps it because
`(namespace, name) in attr_docs` regardless of comment content; for an
*inherited* attribute V1 relies on a truthy `ObjectMember.docstring`, so an
empty comment (`attr_docs == ['']`, joined to `""`) would not keep it. Empty
doc-comments are pathological (no actual documentation), dropping them is
arguably more correct, and matching the local quirk would require an MRO
attr_docs scan inside `filter_members` — disproportionate complexity for zero
practical value. Left as-is.

## Error handling

**F11 — Unanalyzable base modules are handled. VERIFIED.** `ModuleAnalyzer.
for_module()` → `get_module_source()` wraps *all* import failures in
`PycodeError`; the MRO loop's `except (AttributeError, PycodeError): continue`
catches both that and any `safe_getattr` failure. `object` (builtins) and C
modules are skipped cleanly; no uncaught exception can escape the loop.

**F12 — `analyzer.attr_docs` is never `None` at the access point. VERIFIED
(safe).** `ModuleAnalyzer.analyze()` sets `attr_docs` before setting
`_analyzed=True` and converts any failure to `PycodeError` (caught). After a
non-raising `analyze()`, `attr_docs` is always a populated dict, so
`.items()` is safe. This matches the existing `get_attribute_comment`, which
relies on the same invariant.

## Interactions / possible regressions

**F13 — `_find_signature` now runs over the comment, but has no visible effect
for attributes. VERIFIED.** `format_signature` → `_find_signature` → `get_doc`,
which now returns the comment. However `DocstringStripSignatureMixin.
format_signature` assigns only `self.retann` (discards args), `AttributeDocumenter`
has no `format_args`, so `Documenter.format_signature` returns `''` and `retann`
is never rendered for attributes. Typical `#:` comments don't match the
signature RE anyway. `self._new_docstrings` may get set, but
`AttributeDocumenter.get_doc` returns the comment directly and never consults
`_new_docstrings`. No output change.

**F14 — Precedence comment-vs-`__doc__` for inherited attrs is consistent with
the local case. VERIFIED.** For local attributes `Documenter.add_content`
already prioritizes `attr_docs` (comments) over `get_doc()`/`__doc__`. V1 makes
the inherited case behave the same (comment wins). For an inherited attribute
*without* a comment, `get_attribute_comment` returns `None` and the previous
`__doc__`/descriptor behavior (incl. the #7805 `autodoc_inherit_docstrings`
guard) is untouched.

**F15 — Other documenters need no change. VERIFIED.** Methods and properties
carry their documentation on the object's `__doc__`, resolved through normal
attribute inheritance via `getdoc`, so inherited methods/properties already
worked. `DataDocumenter` is module-level (no inheritance) and does not inherit
`get_attribute_comment`; it is untouched. Enum/`__slots__`/TypeVar/NewType/
GenericAlias attribute paths were traced: the comment, when present, correctly
takes precedence (same as the local case); when absent, behavior is unchanged.

**F16 — Redundant comment check remains in
`UninitializedInstanceAttributeMixin.get_doc`. NOTED, intentionally kept.** Now
that `AttributeDocumenter.get_doc` checks the comment first, the mixin's
`if self.object is UNINITIALIZED_ATTR: comment = ...` branch is effectively dead
for `AttributeDocumenter`. It is harmless (returns the same result) and removing
it would alter the mixin's standalone contract for no functional gain; left for
minimal blast radius.

**F17 — `bysource` ordering of inherited members. NOTED, pre-existing.**
Inherited members are not in the subject module's `tagorder`, so they sort last
under `:member-order: bysource`. This already affected inherited methods and is
not introduced by V1.

## Consistency / API contracts

**F18 — `get_class_members` keeps its public signature; `objpath`/`analyzer`
params are now vestigial. ADDRESSED minimally.** The only in-tree caller,
`ClassDocumenter.get_object_members`, passes all four args positionally, and the
4-arg signature also accepts 3-arg calls (`analyzer` defaults to `None`).
Removing the params would break callers/tests, so they are retained for backward
compatibility. V1 reused the name `analyzer` as a loop-local, **shadowing** the
parameter — a readability smell. Fixed by renaming the loop-local to
`cls_analyzer` and documenting that the params are retained for compatibility
(behavior unchanged). This is the only source edit made in V2.

**F19 — Deprecated importer `get_object_members` not updated. CORRECT to leave.**
It feeds only `Documenter.get_object_members` (deprecated,
`RemovedInSphinx60Warning`), which `ClassDocumenter` overrides to use
`get_class_members`. Its `Attribute` namedtuple has no docstring field, so it
cannot carry comment docs without an API change. Out of scope.

## Overall verdict

V1 is functionally correct and complete for the reported issue and the closely
related inherited-instance-attribute case, with no identified regressions. The
only change warranted by the review is the cosmetic de-shadowing in F18; all
other findings are confirmations or negligible, documented edge cases.
