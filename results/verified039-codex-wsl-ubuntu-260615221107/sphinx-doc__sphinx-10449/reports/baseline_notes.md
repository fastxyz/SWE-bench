# Baseline Notes

## Root cause

`sphinx.ext.autodoc.typehints.record_typehints()` records annotations by
introspecting the documented object again during the
`autodoc-process-signature` event. For `autoclass`, that documented object is
the class itself. Sphinx's class documenter already strips constructor return
annotations from the displayed class signature, but the type-hint recorder still
stored the class signature's `return` annotation under the class name. Later,
`merge_typehints()` found that stored `return` entry and injected it into the
class body as an `:rtype:` field, making `__init__() -> None` appear as a
return type for the class.

## Files changed

`repo/sphinx/ext/autodoc/typehints.py`

Skipped recording `return` annotations for `class` and `exception` documenter
types. Parameter annotations are still recorded, so constructor argument types
can continue to be moved into the description when
`autodoc_typehints = "description"` or `"both"` is used. Function and method
return annotations are unchanged.

## Assumptions and alternatives

I assumed class-like object descriptions should not emit `:rtype:` fields,
matching the existing class signature behavior that suppresses constructor
return annotations. I treated `exception` the same way because it uses
`ClassDocumenter` behavior and an exception class also does not have a meaningful
documented return value.

I considered filtering the return annotation later in `merge_typehints()`, but
that function only sees parsed Python domain nodes and annotation dictionaries;
the object type is available earlier and more directly in `record_typehints()`.
I also considered relying on the event's `return_annotation` argument, but that
would lose return annotations for functions when `autodoc_typehints` suppresses
them from the visible signature, so the targeted class-like guard is safer.
