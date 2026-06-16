## Root cause

`floatformat()` converted every input with `repr(text)` and then tried to build a
`Decimal` from that string. For `Decimal` values, `repr()` produces strings such
as `Decimal('42.12345678901234567890')`, which `Decimal()` cannot parse as a
numeric literal. The code then fell back to `float(text)` and converted that
binary float back to `Decimal`, losing precision before rounding and formatting.

## Files changed

* `repo/django/template/defaultfilters.py`: Detects values that are already
  `Decimal` instances and uses them directly, with `str(text)` retained as the
  fallback display value for invalid arguments or non-finite decimal values.
  Non-Decimal inputs keep the existing `repr()` parsing path and `float()`
  fallback.

## Assumptions and alternatives

* I assumed the intended behavior is to preserve exact `Decimal` precision while
  keeping existing float, string, and custom `__float__` behavior unchanged.
* I considered changing the initial conversion for all values from `repr(text)`
  to `str(text)`, which would also parse numeric strings directly, but rejected
  it as broader than the reported Decimal-specific issue.
* I did not modify tests, and I did not run tests or project code per the task
  constraints.
