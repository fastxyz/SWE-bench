# Baseline Notes

## Root Cause

Autodoc discovers class members by iterating over `dir(class)` and calling the active attrgetter for each name. For attributes declared as `@classmethod` over `@property`, that lookup invokes the classmethod descriptor and returns the computed property value instead of the original `property` object. The computed value usually has no relevant docstring, so member filtering treats it as undocumented and skips it. Even when the member is selected, `PropertyDocumenter` imports the member again through the same lookup path, so rendering also loses the property docstring and metadata.

## Files Changed

`repo/sphinx/ext/autodoc/importer.py`

Added `get_class_member()`, which checks the first class in the MRO that defines a member name before using normal attribute access. If the raw class dictionary value is a `classmethod` wrapping a `property`, it returns the wrapped property object; otherwise it falls back to the original attrgetter behavior. `get_object_members()` and `get_class_members()` now use this helper when enumerating class members, preserving class-property docstrings for autodoc and autosummary member classification.

`repo/sphinx/ext/autodoc/__init__.py`

Updated `PropertyDocumenter.import_object()` to reapply the same class-member lookup after the normal import step. This ensures a selected `@classmethod @property` is rendered from the original `property` object, so existing property handling can emit the docstring, `:abstractmethod:`, and return type information.

## Assumptions And Alternatives

I treated `@classmethod @property` as a property for documentation because Sphinx already has a `PropertyDocumenter`, and the Python domain's `property` directive supports the relevant abstract/type metadata. I did not add a new directive option for class properties because the existing domain property directive has no `:classmethod:` option.

The helper stops at the first class in the MRO that defines the name. That preserves normal override behavior and avoids substituting an inherited class-property descriptor when a subclass defines a different member with the same name.

I considered changing the generic `isproperty()` predicate to recognize `classmethod(property(...))`, but that would not fix the second import step where the descriptor had already been evaluated. I also considered documenting the computed value as an attribute, but that would still lose the getter docstring and property-specific metadata.

No tests were run because the task explicitly forbids running tests or code in this benchmark session.
