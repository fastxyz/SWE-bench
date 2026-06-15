# Baseline Notes

## Root cause

`resolve()` returns `None` for named groups in a URL regex when an optional group is not captured. `translate_url()` passes the resulting `ResolverMatch.kwargs` back into `reverse()`. `_reverse_with_prefix()` treated every supplied argument as present and converted values to text before matching, so a missing optional group could become the literal text `None` in the generated URL, or prevent the shorter optional-pattern candidate from being selected.

## Files changed

`repo/django/urls/resolvers.py`

Normalized `None` values out of positional and keyword arguments at the start of `_reverse_with_prefix()`, after the existing mixed args/kwargs validation. This makes `None` from absent optional URL captures behave like an omitted argument, allowing the existing reverse candidate selection to choose the version of the pattern without the optional group.

## Assumptions and alternatives considered

I assumed `None` should mean "argument omitted" only inside URL reversing, matching the issue hint and the behavior of unresolved optional regex captures. Empty strings, zero, and other falsey values are still preserved because they may be valid URL arguments.

I considered changing `translate_url()` to drop `None` from `match.kwargs`, but rejected it because the same asymmetry affects direct `reverse()` calls and the `{% url %}` template tag. Fixing `_reverse_with_prefix()` addresses the shared source of URL construction.

I also considered filtering only keyword arguments, since `translate_url()` passes named captures as kwargs, but rejected that because the public issue discussion also describes the direct positional use case where an optional template argument may evaluate to `None`.

No tests or runtime checks were run, per the task instructions forbidding code execution in this workspace.
