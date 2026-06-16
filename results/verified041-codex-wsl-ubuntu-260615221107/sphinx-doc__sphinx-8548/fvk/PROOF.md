# FVK Proof

Status: constructed, not machine-checked. No tests, Python, Sphinx builds, or K
commands were run.

## Claims Proved in the Constructed Model

C1. Inherited documented class/data attributes are collected with the docstring
from the class that owns the member by Python MRO.

C2. Collected inherited attribute comments cause `autoclass :inherited-members:`
to keep the member as a documented attribute.

C3. Explicit `autoattribute:: Subclass.attr` renders the MRO owner's attribute
comment when the subclass namespace has no direct comment.

C4. If the subclass or an earlier base owns `attr` and has no comment, a later
base's comment is not used.

C5. The inherited-comment content fallback is local to `AttributeDocumenter`; the
base `Documenter` virtual dispatch surface is unchanged from pre-fix behavior.

## Symbolic Proof Sketch

### C1: collection

Assume:

- `Subject.__mro__ = [Subject, ..., Owner, ...]`;
- `_get_class_member_owner(Subject, name) = Owner`;
- `ModuleAnalyzer.for_module(Owner.__module__).find_attr_docs()` contains
  `(Owner.__qualname__, name) -> doc`;
- `name` is visible through `dir(Subject)` or annotations.

Symbolically executing `get_class_members()`:

1. The `dir(subject)` or annotations pass creates a `ClassAttribute` for `name`.
2. `_get_class_member_owner()` records `class_ == Owner` for runtime members, or
   the annotation pass records the annotation owner.
3. The analyzer pass iterates over `getmro(subject)`.
4. At `cls == Owner`, `_get_class_attr_docs()` returns `name -> doc`.
5. The guard `members[name].class_ == cls` holds only for `Owner`, so
   `members[name].docstring = doc`.

Therefore the collected member carries the correct inherited attribute comment.

### C2: filtering

Assume `ClassDocumenter.get_object_members()` wraps the collected member as
`ObjectMember(name, value, docstring=doc)`.

In `filter_members()`:

1. The initial `isattr` is true only for `INSTANCEATTR`.
2. The ObjectMember branch sees `obj.docstring`, sets `doc = obj.docstring`, and
   sets `isattr = True`.
3. `has_doc = bool(doc)` holds for the inherited comment.
4. For a public non-special member not excluded by options, `keep = has_doc or
   undoc_members` evaluates to true.

Therefore the inherited documented data attribute is selected without requiring
`:undoc-members:`.

### C3: explicit autoattribute content

Assume `autoattribute:: Subject.name`, no direct current namespace comment, and
`get_class_attr_doc(Subject, name, analyzer) = doc`.

In `AttributeDocumenter.add_content()`:

1. It computes the direct key `("Subject", "name")`.
2. Because the key is absent from the current analyzer docs, it calls
   `get_attribute_comment(self.parent)`.
3. `get_attribute_comment()` delegates to `get_class_attr_doc()`.
4. The returned `doc` is processed with `process_doc()` and added to output.
5. `no_docstring = True`, so fallback value/object docstrings are suppressed in
   the subsequent `super().add_content()` call.

Therefore explicit `autoattribute` renders the inherited comment body.

### C4: override blocking

Assume `Subject` or an earlier base owns `name`, and a later base has a comment
for the same `name`.

`get_class_attr_doc()` first computes `owner = _get_class_member_owner(Subject,
name)`. If `owner` is set, it checks only `_get_class_attr_docs(owner, analyzer)`.
If that owner lacks a comment, the function returns `None` and does not continue
to later bases. Therefore later-base comments cannot be attached to an overridden
attribute.

### C5: compatibility

The final code does not add `Documenter.get_attribute_comment()` and does not
make `Documenter.add_content()` call a new virtual hook. The new fallback call is
inside `AttributeDocumenter.add_content()`, which already owns attribute-specific
content behavior. Therefore unrelated documenter subclasses see the original
base `Documenter.add_content()` behavior.

## Formal Core

The K sketch files are:

- `fvk/mini-autodoc.k`
- `fvk/autodoc-inherited-attrs-spec.k`

They encode the abstract claims for collection, filtering, explicit content, and
override blocking.

Commands to run in an environment with K installed:

```sh
kompile fvk/mini-autodoc.k --backend haskell
kast --backend haskell fvk/autodoc-inherited-attrs-spec.k
kprove fvk/autodoc-inherited-attrs-spec.k
```

Expected if the sketch is completed into runnable K: `kprove` returns `#Top`.
This session did not run those commands.

## Residual Risk

- Partial correctness only: this proof does not prove termination or performance.
- The K files are an abstract mini-semantics of the relevant autodoc state, not a
  full Python semantics for the literal Sphinx code.
- Test removal is not recommended until a future machine-checked proof and normal
  test run confirm the result.

