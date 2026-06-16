# Formal Spec in English

Status: paraphrase of `fvk/django-serializer-spec.k`; constructed, not
machine-checked.

K-1. For any class-bound method whose class qualified name has no local-scope
marker, `serialize()` reaches a successful serialization whose path is
`module + "." + class_qualname + "." + method_name` and whose import is
`"import " + module`.

K-2. For any class-bound method whose class qualified name contains a local-scope
marker, `serialize()` reaches a `ValueError` outcome saying the function could
not be found in that module.

K-3. For any lambda callable, including one that would otherwise be class-bound,
`serialize()` reaches `ValueError("Cannot serialize function: lambda")`.

K-4. For any non-class-bound, non-local function, `serialize()` reaches the
existing successful serialization whose path is
`module + "." + function_qualname` and whose import is `"import " + module`.

K-5. For any non-class-bound local function, `serialize()` reaches a
`ValueError` outcome saying the function could not be found in that module.

K-6. For any function without a module, `serialize()` reaches the existing
no-module `ValueError` outcome.

K-7. There are no loops in the modeled target; the proof obligations are
straight-line branch obligations, so no loop circularity is required.
