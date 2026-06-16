## Root cause

The `--pastebin` implementation sends pytest terminal output to bpaste.net through
`create_new_paste`, but it labels the submitted content as Python source using
`lexer=python3` on Python 3 and `lexer=python` on Python 2. The uploaded content is
not necessarily Python code; for `--pastebin=all` it is the full terminal session
log, and for `--pastebin=failed` it is a rendered failure report. Some valid pytest
output is rejected by bpaste.net with that Python lexer, while the same arbitrary
text is accepted when submitted as plain text.

## Files changed

`repo/src/_pytest/pastebin.py`

Changed the bpaste.net request parameters in `create_new_paste` to use
`lexer=text`. This matches the actual content being uploaded and avoids service-side
lexer validation failures for non-Python terminal output.

## Assumptions and alternatives considered

I assumed the correct behavior is to classify all pastebin uploads as plain text,
because both supported `--pastebin` modes upload terminal-rendered pytest output
rather than standalone Python source.

I considered only changing the Python 3 branch from `python3` to `text`, because the
reported failure mentions `lexer=python3`. I rejected that because keeping
`lexer=python` on Python 2 would preserve the same conceptual bug for arbitrary
terminal text.

I also considered adding escaping, filtering, or fallback retry behavior around the
HTTP request. I rejected those options because the issue identifies the lexer
selection as the cause, and changing the lexer is the minimal targeted fix.
