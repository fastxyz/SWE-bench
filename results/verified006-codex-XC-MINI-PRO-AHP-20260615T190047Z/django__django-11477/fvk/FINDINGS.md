# FVK Findings

Status: constructed, not machine-checked. No tests or code were executed.

## F1: Reported translation bug is addressed by V1

- Evidence: E1, E2, E3, E6.
- Input: an optional named URL pattern with candidates equivalent to `/optional/%(arg1)s/` and `/optional/%(arg1)s/%(arg2)s/`, called via `translate_url()` after `resolve()` produced `kwargs={'arg1': 1, 'arg2': None}`.
- Pre-V1 observed behavior: the shorter candidate is rejected because `arg2` is treated as an extra supplied key; the longer candidate may stringify `None` or fail pattern validation.
- Expected behavior: `arg2` is absent and the shorter candidate is eligible.
- V1 audit result: `_reverse_with_prefix()` rewrites kwargs to `{'arg1': 1}` before matching candidates, satisfying the expected behavior.
- Classification: fixed code bug.

## F2: Positional `None` use case is covered

- Evidence: E3, E4.
- Input: a direct reverse or `{% url %}` call with positional args equivalent to `[1, None]` for a pattern whose optional second component may be absent.
- Pre-V1 observed behavior: the candidate with one parameter is skipped because two arguments are supplied; `None` can be coerced as a real second value.
- Expected behavior: the optional component is omitted and the one-parameter candidate is eligible.
- V1 audit result: args normalize to `(1,)` before candidate matching.
- Classification: fixed code bug.

## F3: Empty strings remain supplied values

- Evidence: E5.
- Input: a template URL argument resolving to `''`.
- Expected behavior: `''` remains present, so nonexistent template variables are not hidden by the `None` omission rule.
- V1 audit result: the filter removes only values whose identity is `None`; `''`, `0`, and `False` are preserved.
- Classification: confirmed frame condition.

## F4: Mixed positional and keyword argument error is preserved

- Evidence: existing `_reverse_with_prefix()` API behavior and SPEC frame condition.
- Input: a reverse call supplying both positional and keyword arguments.
- Expected behavior: raise `ValueError("Don't mix *args and **kwargs in call to reverse()!")`.
- V1 audit result: the `ValueError` check remains before the new normalization lines.
- Classification: confirmed compatibility.

## F5: Residual proof and modeling limits

- Evidence: FVK methodology and the no-execution constraint.
- Input: full Django regex resolution, converter-specific `to_url()` behavior, quoting, and resolver population.
- Expected behavior: unchanged except for `None` omission before candidate matching.
- V1 audit result: these parts are frame conditions by code inspection; the K model abstracts them.
- Classification: proof capability and execution-environment limit, not a code bug.

