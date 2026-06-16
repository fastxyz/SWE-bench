# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt issue | "Request with binary payload fails due to calling to_native_string" | A binary `data` payload must not be decoded through `to_native_string`. | Encoded by PO-1 and PO-2. |
| E2 | prompt issue | `data=u"...".encode("utf-8")` and "works with 2.8.1, but not with 2.9" | Non-ASCII UTF-8 bytes are in-domain for raw request bodies. | Encoded by PO-2. |
| E3 | source docstring | "`data`: the body to attach to the request" | Raw non-mapping `data` is body data, not URL text. | Encoded by PO-2. |
| E4 | source docstring | "If a dictionary is provided, form-encoding will take place." | Mapping/list data must continue through form encoding. | Encoded by PO-4. |
| E5 | public test | `params=b'test=foo'` prepares `http://example.com/?test=foo` | Bytes URL params need native URL string assembly. | Encoded by PO-3. |
| E6 | public test | `req.data = {'life': '42'}` prepares body `life=42` | Existing form body behavior is a frame condition. | Encoded by PO-4. |
| E7 | source utility docstring | "`to_native_string` ... assumes ASCII unless told otherwise" | Calling it on non-ASCII bytes is the failure mechanism. | Finding F-001. |
| E8 | implementation | `_encode_params` is called from both `prepare_body` and `prepare_url`. | A safe fix must distinguish body bytes from URL query bytes. | Finding F-002 and V2 change. |

No hidden tests, evaluator results, upstream patches, internet sources, or
external benchmark files were used.
