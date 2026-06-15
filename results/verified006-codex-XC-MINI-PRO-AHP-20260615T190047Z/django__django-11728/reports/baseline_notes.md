# Baseline Notes

## Root cause

`django.contrib.admindocs.utils.replace_named_groups()` and
`replace_unnamed_groups()` detected a completed capture group only at the start
of the next loop iteration. That worked when a group was followed by another
character, such as `/`, `$`, or literal text, because the next iteration saw the
balanced bracket count and recorded the group slice.

When a capture group ended at the end of the pattern, there was no next
iteration. The closing `)` reduced the unmatched bracket count to zero, but the
function exited the loop without recording the group. As a result,
`simplify_regex()` left a trailing named or unnamed group unreplaced.

## Changed files

`repo/django/contrib/admindocs/utils.py`

- Moved the balanced-bracket check in `replace_named_groups()` until after the
  current character has been processed.
- Adjusted the recorded slice to include the closing parenthesis that was just
  consumed.
- Made the same change in `replace_unnamed_groups()` so unnamed trailing groups
  are handled consistently.

## Assumptions and alternatives

- I assumed the intended behavior is to simplify a capture group regardless of
  whether it is followed by `/`, `$`, literal text, or the end of the pattern.
- I kept the existing parsing approach and only fixed the off-by-one completion
  behavior. Replacing the scanner with a different parser would be broader than
  the reported issue requires.
- I did not modify tests because the task explicitly requires source-only
  changes. I also did not run tests or project code per the benchmark
  instructions.
