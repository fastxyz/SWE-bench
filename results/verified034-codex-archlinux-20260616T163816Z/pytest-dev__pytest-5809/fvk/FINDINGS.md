# FVK Findings

Status: constructed, not machine-checked.

## F-001: Python lexer for arbitrary pytest output

Classification: code bug, resolved by V1.

Input: pytest terminal output whose contents bpaste.net rejects under the Python
lexer.

Observed before V1: `create_new_paste` built a request with `lexer=python3` on
Python 3, or `lexer=python` on Python 2.

Expected: the request uses `lexer=text`, because pytest console output is arbitrary
text rather than Python source.

Evidence: public issue entries E-001 through E-004. Proof obligation: PO-001.

Status: resolved by `repo/src/_pytest/pastebin.py` line 82 in V1.

## F-002: Public test encodes legacy lexer

Classification: suspect public-test evidence.

Input: `testing/test_pastebin.py::TestPaste::test_create_new_paste`.

Observed: the test computes `lexer = "python3" if sys.version_info[0] >= 3 else
"python"` and asserts that lexer appears in the encoded request body.

Expected per public issue: `lexer=text`.

Evidence: public evidence E-007 conflicts with E-003/E-004. Proof obligation:
PO-005.

Status: do not use this test as a reason to revert V1. The benchmark forbids test
edits, so the test file remains unchanged.

## F-003: Both pastebin modes are covered by the helper-level fix

Classification: compatibility check, no source action required.

Input: `--pastebin=all` and `--pastebin=failed`.

Observed in V1: both modes call `create_new_paste`, and that helper constructs
`lexer=text` independently of the supplied content.

Expected: all pytest pastebin uploads use plain-text classification.

Evidence: public evidence E-006. Proof obligation: PO-004.

Status: discharged by static source inspection.

## F-004: External service and malformed response behavior are outside this proof

Classification: residual integration risk / proof boundary.

Input: network failures, bpaste.net behavior unrelated to the lexer field, or
malformed response HTML.

Observed: this FVK model stops at request construction and successful response URL
shape.

Expected: no source change is justified for these cases by the issue text.

Evidence: the public issue localizes the failure to the lexer value and gives
`lexer=text` as the successful alternative. Proof obligations: PO-001 and PO-003.

Status: no additional code edit.
