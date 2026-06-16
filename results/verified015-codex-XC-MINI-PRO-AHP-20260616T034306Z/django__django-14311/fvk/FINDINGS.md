# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and the constructed proof obligations. No tests or
project code were run.

## Findings Summary

No open production-code bug remains in V1 for the audited behavior. The findings
below document the pre-V1 defect, the corner cases audited by FVK, and the
residual proof/testing caveat.

## F1: Pre-V1 dotted module truncation

Classification: code bug, resolved by V1.

Evidence:

- Intent ledger E1 and E2 require `python -m foo.bar.baz runserver` to restart
  with `-m foo.bar.baz`.
- The issue reports the buggy result as `-m foo.bar`.

Input:

- `BASE = [sys.executable]`
- `TAIL = ["runserver"]`
- `Spec = moduleSpec("foo.bar.baz")`

Observed before V1:

- The old implementation used `__spec__.parent`, producing
  `[sys.executable, "-m", "foo.bar", "runserver"]`.

Expected:

- `[sys.executable, "-m", "foo.bar.baz", "runserver"]`.

V1 status:

- Discharged by PO1. Lines 226 through 235 in `repo/django/utils/autoreload.py`
  select `spec.name` for non-`.__main__` specs and return with `-m` plus the
  original tail.

## F2: `foo.my__main__` must not be treated as package `__main__`

Classification: corner case, resolved by V1.

Evidence:

- Intent ledger E3 names `foo.my__main__` as a corner case that should not be
  detected by splitting the last dotted component.

Input:

- `Spec = moduleSpec("foo.my__main__")`
- `TAIL = ["runserver"]`

Expected:

- The restart target remains `foo.my__main__`.

V1 status:

- Discharged by PO1 and PO2. V1 checks exact `__main__` or suffix
  `.__main__`, so `foo.my__main__` follows the ordinary module branch.

## F3: Package `__main__` behavior is preserved

Classification: compatibility behavior, confirmed.

Evidence:

- Intent ledger E4 covers existing package entry-point behavior such as
  `python -m django` and the package `__main__` fixture.

Input:

- `Spec = packageMainSpec("django")`
- `TAIL = ["runserver"]`

Expected:

- `[sys.executable, "-m", "django", "runserver"]`.

V1 status:

- Discharged by PO2. V1 still uses `spec.parent` for exact `__main__` or
  `.__main__` package specs.

## F4: Non-`-m` fallback behavior is preserved

Classification: compatibility behavior, confirmed.

Evidence:

- Intent ledger E5 covers warning options, direct script execution, `.exe`
  entry points, `-script.py` entry points, and missing-script errors.

Expected:

- `noSpec` and spec-with-empty-module-name states fall through to the existing
  script path checks.

V1 status:

- Discharged by PO3 through PO7. V1's early return occurs only after a truthy
  `module_name` is selected; otherwise the existing fallback branch executes.

## F5: Proof and test-removal caveat

Classification: proof status, not a code bug.

Evidence:

- The FVK instructions require artifacts to be labeled "constructed, not
  machine-checked" when `kompile` and `kprove` are not executed.
- The task forbids running tests, Python, or K tooling.

Expected:

- Do not claim machine-checked proof success and do not remove tests.

V1 status:

- The proof is constructed only. Existing and hidden tests should be kept. The
  test additions in `fvk/ITERATION_GUIDANCE.md` are recommendations only.
