# Baseline Notes

## Root Cause

`kernS` uses a temporary placeholder symbol named `kern` only when its string
rewrites introduce spaces. For inputs such as `(2*x)/(x-1)`, the string has
parentheses but none of the rewrites introduce a space, so the `if ' ' in s:`
branch does not run and `kern` is never assigned. The following unconditional
`hit = kern in s` statement then raises `UnboundLocalError`.

## Files Changed

`repo/sympy/core/sympify.py`

Moved the `hit = kern in s` assignment inside the branch that creates and
substitutes the temporary `kern` placeholder. `hit` is already initialized to
`False`, so strings that do not need the placeholder now continue through normal
sympification instead of referencing an undefined local.

## Assumptions and Alternatives

I assumed that `kernS` should only perform its placeholder cleanup path when it
actually inserted a placeholder. That matches the existing `hit` flag and the
later `if not hit: return expr` branch.

An alternative would have been to initialize `kern` to a sentinel value before
the rewrite block. I rejected that because it would leave the later code able to
report a placeholder hit even when no placeholder had been inserted. Keeping the
`hit` update within the placeholder branch is the smallest change and preserves
the existing fallback behavior for strings that do use the hack.
