# Public Compatibility Audit

Constructed, not machine-checked.

Changed public symbol:

- `sphinx.domains.python.PyMethod.get_index_text(self, modname, name_cls)`

Compatibility observations:

1. Signature unchanged: no callers or overrides need new arguments.
2. Return type unchanged: still returns a string index label.
3. `PyObject.add_target_and_index()` still consumes the return value in the same
   way and appends a `('single', indextext, node_id, '', None)` entry.
4. Object registration remains `domain.note_object(fullname, self.objtype, ...)`;
   `py:method :property:` continues to register as object type `method`.
5. Subclasses `PyClassMethod`, `PyStaticMethod`, and `PyDecoratorMethod` inherit
   the method but do not gain any signature or protocol change.

Compatibility verdict: PASS. The change is observable only in index-entry text
for property-option cases and in the intentional removal of callable
parentheses from that text.
