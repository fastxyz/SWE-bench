# Public Evidence Ledger

Constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "An index entry with parens was registered for `py:method` directive with `:property:` option." | The defect is in index text for `PyMethod` when `property` is present. | Encoded by PO-1 and PO-2. |
| E2 | prompt | "It should not have parens." | Property-option index entries must not be callable-shaped. | Encoded by PO-2, PO-3, PO-4. |
| E3 | prompt | Reproduction pairs `.. py:method:: Foo.bar :property:` with `.. py:property:: Foo.baz`. | `py:method :property:` should follow the existing `py:property` index shape. | Encoded by PO-2 and PO-3. |
| E4 | source | `PyMethod.needs_arglist()` returns `False` when `property in self.options`. | The signature already treats the directive as non-callable; index text should be consistent. | Supports PO-2. |
| E5 | source | `PyProperty.get_index_text()` returns `'%s (%s property)'` for qualified properties and no `()` in module/no-module fallback. | Existing property formatting is the reference shape. | Supports PO-2 and PO-3. |
| E6 | public-test | `test_domain_py.py` expects `meth5() (Class property)`. | SUSPECT legacy expectation because it asserts the reported bug. | Finding F-002; not encoded as desired behavior. |
| E7 | source | `PyObject.add_target_and_index()` appends `get_index_text()` output and separately registers the object. | Changing index text is sufficient; object registration should remain untouched. | Encoded by PO-6 and PO-7. |
