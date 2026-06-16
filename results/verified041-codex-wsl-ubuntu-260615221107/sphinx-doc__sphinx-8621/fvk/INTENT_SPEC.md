# Intent Specification

This file records intent before accepting candidate behavior as correct.

1. A `:kbd:` role marks a sequence of keystrokes.
2. A standalone `-`, `+`, or `^` inside `:kbd:` is a keystroke, not a compound
   separator, and should render as one `kbd` element.
3. In a compound keystroke, `-`, `+`, and `^` must be interpreted by position:
   separator position means separator; key position means key text.
4. Existing ordinary compound syntax, including `Control+X` and `M-x  M-s`,
   must continue to render as nested key nodes separated by literal separator
   text.
5. The fix is limited to HTML keyboard-role transformation and should not
   change role registration, non-HTML writers, public build commands, or test
   files.
6. Malformed adjacent separators or missing key text are not specified by the
   public issue.
