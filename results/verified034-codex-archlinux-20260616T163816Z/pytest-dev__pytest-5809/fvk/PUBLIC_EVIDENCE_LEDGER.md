# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | prompt | "`--pastebin` option currently submits the output of `pytest` to `bpaste.net` using `lexer=python3`" | The audited observable is the bpaste request body emitted by `create_new_paste`. | Encoded in SPEC.md and pastebin-spec.k. |
| E-002 | prompt | "For some `contents`, this will raise a `HTTP Error 400: Bad Request`." | A Python lexer is an invalid classification for at least some in-domain pytest output. | Finding F-001. |
| E-003 | prompt | "The call goes through fine if `lexer` is changed from `python3` to `text`." | Expected lexer is exactly `text`. | Proof obligation PO-001. |
| E-004 | prompt | "the console output of a `pytest` run that is being uploaded is not Python code, but arbitrary text" | The obligation applies to pytest output generally, not only to one attached payload. | Proof obligations PO-001 and PO-004. |
| E-005 | source | `create_new_paste` builds `params` with `code`, `lexer`, `expiry` and sends it to `https://bpaste.net`. | The formal model must preserve those request fields as observables. | Encoded in mini-pastebin.k. |
| E-006 | source | `pytest_unconfigure` and `pytest_terminal_summary` both call `create_new_paste`. | The helper-level fix covers both pastebin modes. | Proof obligation PO-004. |
| E-007 | public-test | `testing/test_pastebin.py` expects `lexer=python3` or `lexer=python`. | Legacy expectation conflicts with E-003/E-004 and must not veto the intent. | Finding F-002, marked SUSPECT. |
