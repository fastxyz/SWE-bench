# Formal Spec English

Status: constructed, not machine-checked.

## Claim C-001: request construction

For every paste content value `CONTENTS` in the intended domain of pytest terminal
output, the request constructed for bpaste.net has:

- URL: `https://bpaste.net`
- code field: exactly `CONTENTS`
- lexer field: exactly `text`
- expiry field: exactly `1week`

The claim is independent of Python runtime version and independent of the concrete
content bytes or text, so there is no path that emits `lexer=python3` or
`lexer=python`.

## Composition through pytest modes

Both pastebin modes call `create_new_paste`; therefore proving Claim C-001 for all
contents proves that `--pastebin=all` and `--pastebin=failed` submit terminal output
as plain text, provided they reach the helper.
