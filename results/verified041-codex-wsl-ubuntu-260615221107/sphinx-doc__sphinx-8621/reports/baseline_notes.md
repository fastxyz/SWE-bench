# Baseline Notes

## Root Cause

The HTML post-transform for the `:kbd:` role split keyboard text with a single
regular expression that treated every `-`, `+`, `^`, and whitespace run as a
separator. That created empty nested `<kbd>` elements when one of those
characters was the key itself, such as `:kbd:`-`` or `:kbd:`+``. It also broke
compound keystrokes such as `:kbd:`Shift-+`` because the `+` at the key position
was still interpreted as another separator.

## Changed Files

`repo/sphinx/builders/html/transforms.py`

Replaced the regex split in `KeyboardTransform` with a small positional parser.
The parser reads the text as alternating key and separator positions. A
separator-looking character in a key position is kept as part of the key, while
whitespace runs and `-`, `+`, or `^` in separator positions still split normal
compound keystrokes. This preserves the existing behavior for examples such as
`Control+X` and `M-x  M-s`, while preventing empty key nodes for standalone or
adjacent separator characters.

`reports/baseline_notes.md`

Added this required report describing the root cause, changed files,
assumptions, and rejected alternatives.

## Assumptions and Rejected Alternatives

I assumed the separator characters are only separators when they can separate
two keystrokes. At the start or end of the text, or immediately after another
separator where a key is expected, they represent literal keys.

I considered special-casing only the reported examples, but rejected that
because the same failure applies equally to all three separator characters in
the same positions. I also considered keeping the regex and adding lookaround
conditions, but that would still be awkward for adjacent separator characters
such as `Shift--` or `Control++`; an explicit positional parser makes the rule
clear without changing unrelated writer behavior.
