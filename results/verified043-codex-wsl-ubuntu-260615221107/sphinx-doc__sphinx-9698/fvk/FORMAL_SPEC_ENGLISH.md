# Formal Spec English

Constructed, not machine-checked.

The K claims in `python-domain-index-spec.k` mean:

1. If the `property` option is true and the name is qualified, then
   `getIndexText` returns `propertyClass(method_name, displayed_class_name)`.
   In Sphinx text form, that is `method_name (displayed_class_name property)`,
   with no callable parentheses.
2. If the `property` option is true and the name is unqualified with a module,
   then `getIndexText` returns `propertyModule(name, module)`, corresponding to
   `name (in module module)` and no callable parentheses.
3. If the `property` option is true and the name is unqualified without a
   module, then `getIndexText` returns `propertyPlain(name)`, corresponding to
   the bare `name`.
4. For every modeled input with `property` true, `hasCallableParens` is false.
   This includes cases where `classmethod` or `staticmethod` is also true.
5. For every modeled input with `property` false, `hasCallableParens` is true,
   preserving method/classmethod/staticmethod callable index shape.

No loop circularities are needed because `PyMethod.get_index_text()` has no loop
or recursion. The proof is partial correctness over this branch model.
