# Intent Spec

Status: constructed, not machine-checked.

## Required behavior

1. `--pastebin` uploads pytest terminal output to bpaste.net.
2. The uploaded content is arbitrary pytest console text, not Python source.
3. The bpaste request must therefore use `lexer=text` rather than `lexer=python3`
   or `lexer=python`.
4. The change is about the paste metadata. It should not alter the paste contents,
   destination URL, expiry, public helper signature, or response URL extraction.
5. Both supported modes, `--pastebin=all` and `--pastebin=failed`, must receive the
   same plain-text lexer behavior because both upload terminal-rendered pytest
   output through `create_new_paste`.

## Out of scope for this issue

Network availability, bpaste.net service-side behavior beyond the lexer field, and
malformed response handling are not specified by the issue. They remain residual
integration risks, not reasons to change the source for this audit.
