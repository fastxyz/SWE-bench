# Intent Specification

Intent-only obligations from public evidence:

1. `model_to_dict(instance, fields=[])` returns an empty dictionary.
2. A provided `fields` list restricts output to the names in that list.
3. `fields=None` means no inclusion filter was provided.
4. `exclude` removes named fields even when those names are also present in
   `fields`.
5. Filtered-out fields are not read merely to build the result.
6. The repair preserves the `model_to_dict()` signature and return shape.

No hidden tests, evaluator outputs, or upstream patch knowledge are intent
sources for this specification.
