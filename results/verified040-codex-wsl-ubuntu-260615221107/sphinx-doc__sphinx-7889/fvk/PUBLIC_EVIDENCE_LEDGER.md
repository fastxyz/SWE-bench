# Public Evidence Ledger

| ID | Source | Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "Autodoc extension's mock file throws TypeError for generic-typed classes." | Generic class use through autodoc mock imports is in domain. | Encoded in SPEC and K claims. |
| E2 | prompt | "`mock._make_subclass` attempts to concatenate a `str` to a `TypeVar`." | `_make_subclass` must normalize non-string names before string concatenation. | Encoded in PO1-PO4. |
| E3 | prompt | "Docs can still be built when generics are involved." | Generic subscription on mocked classes must not abort the documentation build. | Encoded in mockGetItem claim. |
| E4 | public test | `repr(mock.some_attr) == 'mocked_module.some_attr'` and chained dotted repr assertions. | Preserve string-name dotted display behavior. | Encoded in string-name claim and PO3. |
| E5 | public code/tests | `sphinx.util.typing.stringify(TypeVar('T')) == "T"` in the type utility tests. | Using a string `__name__` for `TypeVar` is compatible with existing Sphinx type naming. | Encoded as default-domain support for TypeVarName. |
| E6 | implementation | `_MockObject.__getitem__` delegates to `_make_subclass(key, self.__display_name__, self.__class__)()`. | The proof must cover the subscript path, not only direct helper calls. | Encoded in mockGetItem claim. |
| E7 | compatibility search | `_make_subclass` is internal to `mock.py`; `_MockObject` is re-exported from `autodoc.importer`; no public callers with the old `name: str` annotation were found. | Changing the annotation to `Any` and normalizing internally must preserve arity and call shape. | Covered by PUBLIC_COMPATIBILITY_AUDIT. |
