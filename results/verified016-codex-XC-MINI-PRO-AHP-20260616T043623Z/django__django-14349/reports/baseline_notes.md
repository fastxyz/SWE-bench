# Baseline Notes

## Root cause

`URLValidator` first validates URLs with its regular expression. If that fails, it falls back to splitting the URL with `urllib.parse.urlsplit()` so it can punycode an internationalized domain name and validate the reconstructed URL.

Python versions patched for bpo-43882 remove ASCII tab, carriage return, and line feed characters before splitting. That means an invalid URL such as `http://www.djangoproject.com/\n` can fail Django's regex, enter the IDN fallback, be split with the newline silently removed, be reconstructed as a valid URL, and pass validation.

## Files changed

`repo/django/core/validators.py`

Added an `unsafe_chars` class attribute to `URLValidator` containing `\t`, `\r`, and `\n`, and reject values containing those characters before scheme validation or the `urlsplit()` fallback. This preserves the validator's existing behavior that such whitespace makes a URL invalid, regardless of Python's URL splitting normalization.

## Assumptions and alternatives

I assumed Django should continue rejecting URLs containing tab, carriage return, or line feed characters because the existing regular expression already rejects whitespace and the public issue reports tests that expect `ValidationError` for newline-containing URLs.

I considered replacing `urllib.parse.urlsplit()` in the validator with Django's private `_urlsplit()` helper from `django.utils.http`, which does not perform the newer stripping behavior. I rejected that because the issue is specifically about characters that should make the original input invalid before parsing, and an explicit early check is smaller and less likely to alter valid IDN handling or other parsing edge cases.

I also considered allowing Python's stripping behavior and accepting the normalized URL, but rejected it because that would change Django's validation contract and contradict the existing invalid URL cases described in the issue.
