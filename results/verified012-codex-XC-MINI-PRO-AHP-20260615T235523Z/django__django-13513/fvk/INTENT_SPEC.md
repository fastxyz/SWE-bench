# Intent Spec

Status: constructed from public benchmark inputs, not from hidden tests or evaluator results.

## Required Behavior

1. The debug error reporter must follow Python exception chaining semantics for explicit and implicit causes.
2. If an exception has a non-`None` `__cause__`, that explicit cause is the next visible exception.
3. If `__cause__` is `None` and `__suppress_context__` is true, the implicit `__context__` is suppressed and must not be shown by the technical 500 traceback.
4. If `__cause__` is `None` and `__suppress_context__` is false, the implicit `__context__` remains visible.
5. For the reported example, `ValueError("my new error")` raised `from None` while handling `RuntimeError("my error")` must not display the `RuntimeError` in the debug traceback.
6. The frame metadata consumed by the debug templates must distinguish explicit direct causes from implicit context so the correct "direct cause" vs "During handling" message is selected.

## Domain

The verified domain is the exception-chain portion of `ExceptionReporter.get_traceback_frames()`: exception objects with Python exception chaining attributes `__cause__`, `__context__`, and `__suppress_context__`, plus the frame metadata derived from those attributes. File reading, source context extraction, variable filtering, and HTML/text escaping are outside this issue's behavioral surface.

## Default-Domain Assumptions

- `None` is the sentinel for "no explicit cause" and "no implicit context".
- PEP 415 semantics determine whether `__context__` is visible.
- The FVK proof is partial correctness only and is constructed, not machine-checked.
