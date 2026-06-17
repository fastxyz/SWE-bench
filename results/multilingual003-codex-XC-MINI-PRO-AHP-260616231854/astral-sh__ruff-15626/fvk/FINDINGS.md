# FVK Findings

Status: constructed, not machine-checked. These findings come from public intent and static source inspection only.

## Findings

### F-001: Pre-fix unconditional safe applicability violated the issue intent

Input pattern: `not a == b` or `not a != b` with arbitrary operands.

Observed before V1: SIM201 and SIM202 always used `Fix::safe_edit`, so `ruff --fix` could apply the rewrite by default.

Expected by E-001 and E-002: unsafe unless both operands are known bool-comparison operands.

Classification: code bug, resolved by V1 and preserved by V2.

Related obligations: PO-001, PO-002.

### F-002: Reported NumPy names must be unsafe

Input pattern:

```python
import numpy as np
a = np.array([0])
b = np.array([1])
not a == b
not a != b
```

Observed before V1: the fix was safe and could be applied by `--fix`, changing scalar boolean output to NumPy array output.

Expected by E-004: `np.array(...)` is an unknown third-party call for this rule, so both SIM201 and SIM202 fixes are unsafe.

Classification: code bug, resolved by V1 and preserved by V2.

Related obligations: PO-002, PO-003.

### F-003: V1 over-trusted annotations when a binding had an initializer

Input pattern:

```python
import numpy as np
a: int = np.array([0])
b: int = np.array([1])
not a == b
```

Observed in V1 by static audit: `typing::is_int` can report true from the annotation even when the initializer is an unknown call. Because V1 checked semantic helpers before `find_binding_value`, this pattern could be marked safe.

Expected by E-002, E-004, and E-006: if a binding has an initializer, classify the operand from the initializer first. The unknown `np.array(...)` initializer must make the fix unsafe.

Classification: code bug in V1, fixed in V2 by checking `typing::find_binding_value` before annotation-oriented helpers.

Related obligations: PO-003, PO-004.

### F-004: The known-safe set is conservative and may leave some safe cases unsafe

Input pattern: operands whose runtime `__eq__` and `__ne__` return `bool`, but Ruff has no local evidence category for them.

Observed in V2: such operands receive `Applicability::Unsafe`.

Expected by E-001 and E-003: this is acceptable for safety because the issue requires avoiding unsafe automatic fixes; it only loses an optional safe-fix optimization.

Classification: residual usability gap, not a correctness bug.

Related obligations: PO-002, PO-006.

### F-005: Formal proof and test-redundancy recommendations are not machine-checked

Input pattern: all proof obligations in this FVK run.

Observed: the environment forbids running K tooling, tests, Python, or Ruff.

Expected: artifacts must include exact commands and remain labeled constructed, not machine-checked.

Classification: proof process limitation, not a code bug.

Related obligations: PO-007.
