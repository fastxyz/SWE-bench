# Formal Specification in English

Status: English paraphrase of the K claims, constructed but not
machine-checked.

## Claim C1: Empty Guard

For input `None`, the modeled `trim_docstring()` computation returns the empty
string.

For any string `S` where `isBlank(S)` is true, the modeled
`trim_docstring(S)` computation returns the empty string.

## Claim C2: Non-Empty Dispatch

For any string `S` where `isBlank(S)` is false, the modeled
`trim_docstring(S)` computation returns `cleanDoc(S)`.

## Claim C3: PEP 257 Cleandoc Property

For any non-blank string `S`, `cleanDoc(S)` is the PEP 257-cleaned text:
the first line is left-trimmed, the common margin is computed from non-empty
lines after the first line, and an empty set of following non-empty lines uses
margin `0` rather than raising an error.

## Claim C4: First-Line Summary Directive Safety

For a non-blank docstring `S` whose summary begins on the first line and whose
later lines are indented only because they appear inside a Python function body,
`cleanDoc(S)` removes that function-body indentation before admindocs passes
the text to `parse_rst()`. Therefore the inserted text is not directive content
for the preceding `default-role` directive solely because of retained
docstring indentation.

## Claim C5: Leading-Empty-Line Compatibility

For a non-blank docstring `S` whose first physical line is empty, `cleanDoc(S)`
matches the PEP 257 output expected by the public admindocs utility test. This
keeps the existing Django-style docstring behavior within the same contract.

## Claim C6: Public API Frame

The audited change does not alter the public helper's parameter list or return
shape. All admindocs callsites still pass one docstring-like value and consume a
string.
