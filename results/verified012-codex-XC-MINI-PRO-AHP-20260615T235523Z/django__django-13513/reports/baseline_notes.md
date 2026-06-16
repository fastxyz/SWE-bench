# Baseline Notes

## Root cause

The debug exception reporter builds the displayed traceback by walking each exception's explicit cause or implicit context in `ExceptionReporter.get_traceback_frames()`. For `raise ... from None`, Python keeps the handled exception on `__context__` but sets `__suppress_context__` so traceback renderers should stop at the raised exception instead of showing the suppressed context.

If the reporter falls back to `__context__` when `__suppress_context__` is true, the technical 500 page displays the original handled exception even though Python's normal traceback hides it. The cause resolution helper is therefore the right place to enforce PEP 415 behavior before frames are collected or rendered.

## Changed files

### `repo/django/views/debug.py`

Updated `explicit_or_implicit_cause()` inside `ExceptionReporter.get_traceback_frames()` so it:

- Returns an explicit `__cause__` only when it is not `None`.
- Returns `None` immediately when `__suppress_context__` is true.
- Uses `__context__` only for unsuppressed implicit exception chaining.

This keeps suppressed contexts out of both the exception chain traversal and the `exc_cause` metadata attached to rendered frames. The explicit-cause check is identity-based rather than truthiness-based so an explicit exception object is respected even if it has unusual boolean behavior.

## Assumptions and alternatives

- Assumed the intended behavior should match Python traceback semantics for `raise ValueError(...) from None`: the new exception is shown, but the handled exception stored in `__context__` is not.
- Assumed no template changes were needed because the HTML and text templates only render the `exc_cause` values supplied by `get_traceback_frames()`.
- Considered changing only the rendered frame metadata, but rejected that because the same helper is also used to build the exception chain. Fixing traversal prevents suppressed exceptions from contributing frames at all.
- Did not modify tests, per the benchmark instructions. Tests were not run because this session is restricted from executing code.
