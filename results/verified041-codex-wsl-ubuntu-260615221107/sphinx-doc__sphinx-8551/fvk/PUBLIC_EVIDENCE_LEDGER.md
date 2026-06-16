# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt / issue | "`:type:` and `:rtype:` gives false ambiguous class lookup warnings" | Field-generated Python type xrefs must not produce false ambiguity for the reproduced unqualified `A` cases. | Encoded by O3/O4. |
| E2 | prompt / issue | "lookup differently than explicit xref roles" | Field-generated type xrefs should carry the same Python scope metadata and leading-prefix semantics as explicit roles. | Encoded by O1/O2. |
| E3 | prompt / issue | "BUG: links to mod.A instead of mod.submod.A" | In `py:currentmodule = mod.submod`, plain field type `A` resolves to `mod.submod.A`. | Encoded by O4. |
| E4 | prompt / issue | "No warnings, and the two mentioned types should resolve to `mod.submod.A`." | The reproduction must have a single target for `A` under `mod.submod`, not an ambiguous target set. | Encoded by O4. |
| E5 | prompt / hint | "silently wrong cross-reference ... in non-module scope" | Plain unqualified field targets outside module context must not trigger suffix-fuzzy resolution. | Encoded by O5. |
| E6 | source comment | `PyXrefMixin` says inline type specifiers behave like `:class:` for `"." and "~" prefixes`; `PyXRefRole.process_link()` sets `refspecific` only for leading `.`. | `.A` sets `refspecific`; `~mod.A` only shortens display and strips the target prefix. | Encoded by O2. |
| E7 | public test, SUSPECT | `test_domain_py_xrefs` expected type-field refs such as `int`, `tuple`, `list`, and `ModTopLevel` to omit `py:module` / `py:class` under a current module. | This encodes legacy missing-context behavior that conflicts with E1-E4, so it must not veto the issue-derived spec. | Recorded as Finding F2. |
| E8 | implementation | `Field.make_xref()` calls `env.get_domain(domain).process_field_xref(refnode)` for doc-field xrefs; base `Domain.process_field_xref()` is a hook for current scope. | Python should implement the hook by copying `py:module` / `py:class`. | Encoded by O1. |
| E9 | implementation | `resolve_xref()` derives `searchmode = 1 if node.hasattr('refspecific') else 0`. | Correctness depends on field xrefs setting `refspecific` exactly when explicit roles would. | Encoded by O2/O5. |
