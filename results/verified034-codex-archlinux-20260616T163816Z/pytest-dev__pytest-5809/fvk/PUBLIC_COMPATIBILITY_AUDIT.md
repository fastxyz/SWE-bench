# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed symbol

`repo/src/_pytest/pastebin.py:create_new_paste(contents)`

- Signature: unchanged.
- Return shape on successful bpaste response: unchanged, still
  `https://bpaste.net/show/<id>`.
- Destination URL: unchanged, still `https://bpaste.net`.
- Expiry field: unchanged, still `1week`.
- Request metadata changed: `lexer` is now `text`.

## Public callsites

| Callsite | Compatibility status |
| --- | --- |
| `pytest_unconfigure`, for `--pastebin=all` | Compatible. It passes the captured terminal session bytes to the same helper. |
| `pytest_terminal_summary`, for `--pastebin=failed` | Compatible. It passes rendered failure text to the same helper. |

## Public tests

`testing/test_pastebin.py::TestPaste::test_create_new_paste` checks for the legacy
Python lexer. Under the FVK intent-evidence rules this is SUSPECT because it
conflicts with the issue text identifying that lexer as the bug. The benchmark
forbids modifying tests, so no test file was changed.
