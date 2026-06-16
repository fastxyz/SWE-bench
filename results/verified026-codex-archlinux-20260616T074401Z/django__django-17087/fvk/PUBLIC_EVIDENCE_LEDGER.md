# Public Evidence Ledger

Status: constructed from allowed public inputs only.

| ID | Source | Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E-1 | `benchmark/PROBLEM.md` | "The right value should be `appname.models.Profile.Capability.default`." | Importable nested class methods must include outer class qualifiers. | Encoded by PO-1 and K claim 1. |
| E-2 | `benchmark/PROBLEM.md` public hint | "`FunctionTypeSerializer` should use `__qualname__` instead of `__name__`." | The class component in class-bound method serialization must be `klass.__qualname__`. | Encoded by PO-1. |
| E-3 | `repo/django/db/migrations/serializer.py` | Non-class-bound branch rejects `"<locals>"` in function `__qualname__`. | Local-scope callable paths are not valid migration references. | Encoded by PO-2 and PO-5. |
| E-4 | `repo/tests/migrations/test_writer.py` | `test_serialize_local_function_reference()` expects a local function reference to raise `ValueError`. | Reject local callables rather than serializing them. | Encoded by PO-2. |
| E-5 | `repo/django/db/migrations/serializer.py` | Lambda branch raises `ValueError("Cannot serialize function: lambda")`. | Lambda rejection is a general callable serializer rule. | Encoded by PO-4. |
| E-6 | `repo/tests/migrations/test_writer.py` | `test_serialize_nested_class()` expects nested classes to use `WriterTests.<NestedClass>`. | Django migration serialization already treats `__qualname__` as the representation for nested classes. | Supporting evidence for PO-1 and PO-3. |
