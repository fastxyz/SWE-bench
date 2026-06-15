# Baseline Notes

## Root cause

`ASCIIUsernameValidator` and `UnicodeUsernameValidator` used the regular expression `r'^[\w.@+-]+$'`. Django's `RegexValidator` runs the regex with `search()`, so the anchors are responsible for enforcing that the entire value matches. In Python regular expressions, `$` also matches just before a trailing newline, which allowed usernames ending in `\n` even though newline is not in the permitted character set.

## Changed files

`repo/django/contrib/auth/validators.py`

Changed both username validator regexes to `r'\A[\w.@+-]+\Z'`. This keeps the same allowed characters and the same ASCII/Unicode flag behavior, while using absolute start and end-of-string anchors so a trailing newline is rejected.

## Assumptions and alternatives considered

I assumed the issue is specifically about the two public username validator classes in `django.contrib.auth.validators`, as described in the report. I did not change unrelated validators or model fields.

I considered using `r'^[\w.@+-]+\Z'`, which would also reject a trailing newline in this context because the validators do not use `re.MULTILINE`. I rejected it in favor of `\A...\Z` because the issue explicitly asks for absolute anchors and that avoids any future interaction with multiline matching flags.
