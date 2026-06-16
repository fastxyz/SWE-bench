# Public Evidence Ledger

Status: constructed for audit; not machine-checked.

| ID | Source | Evidence | Semantic Obligation | Status |
|---|---|---|---|---|
| E1 | prompt/issue | "The default value for positional only argument has vanished" | Positional-only defaults are part of the intended rendered signature. | Encoded in SPEC O1, CLAIM-ALIGN-GENERAL, and CLAIM-ISSUE-EXAMPLE. |
| E2 | prompt/issue | `.. py:function:: foo(a, b=0, /, c=1)` | The concrete in-domain example must render `b=0` and `c=1` with `/` between positional-only and later parameters. | Encoded in SPEC O2 and K claim CLAIM-ISSUE-EXAMPLE. |
| E3 | prompt/issue | "Expected behavior: The default value is shown." | The default must be present on the default rendering path, not only in an alternate parser or fallback. | Encoded in SPEC O3 and proof obligation PO-005. |
| E4 | implementation/default-domain | `sphinx/pycode/ast.py` pads `node.defaults` across `node.posonlyargs + node.args`. | Python AST positional defaults align against the combined positional parameter sequence. | Encoded as default-domain assumption D1 and proof obligation PO-001. |
| E5 | public tests | `test_signature_from_str_default_values` checks ordinary defaults; `test_signature_from_str_kwonly_args` checks keyword-only shape; `test_signature_from_str_positionaly_only_args` checks positional-only kind. | Preserve existing default parsing and parameter-kind behavior while adding missing positional-only defaults. | Encoded in frame obligations PO-006 and PO-007. |
| E6 | implementation/callsites | `_parse_arglist()` renders `param.default` whenever it is not `Parameter.empty`. | If `signature_from_str()` returns a positional-only parameter with `default='0'`, rendering will show the default. | Encoded in proof obligation PO-005. |
| E7 | implementation/callsites | `signature_from_str()` is imported by `sphinx.domains.python`; source callsites pass one positional `signature`. | Public API compatibility requires the helper signature and return shape to stay stable. | Encoded in compatibility obligation PO-008. |
