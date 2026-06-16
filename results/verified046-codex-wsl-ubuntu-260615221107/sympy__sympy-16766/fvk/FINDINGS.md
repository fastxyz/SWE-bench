# FVK Findings

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were executed.

## Findings

### F-001: Resolved bug - `Indexed` reached the unsupported fallback

Input:

```python
p = IndexedBase("p")
pycode(p[0])
```

Observed before V1, from the issue:

```text
  # Not supported in Python:
  # Indexed
p[0]
```

Expected from public intent: `p[0]` without the unsupported preamble.

Root cause: `PythonCodePrinter` lacked `_print_Indexed`, so printer dispatch
fell through to `CodePrinter._print_Expr`, which calls `_print_not_supported`.

V1 status: resolved by `PythonCodePrinter._print_Indexed`. See PO-001 and
PO-004.

### F-002: Resolved dependent case - `Idx` would otherwise remain unsupported

Input class:

```python
A = IndexedBase("A")
i = Idx("i")
pycode(A[i])
```

Observed before V1 by source-level dispatch reasoning: adding only
`_print_Indexed` would recursively call `self._print(i)`. Since `Idx` is an
`Expr` and PythonCodePrinter had no `_print_Idx`, it would reach the same
unsupported `Expr` fallback.

Expected from Indexed support: `A[i]` with no unsupported `Idx` preamble.

V1 status: resolved by `PythonCodePrinter._print_Idx`, which prints
`expr.label`. See PO-002 and PO-004.

### F-003: Confirmed - multidimensional index order and separator are preserved

Input class:

```python
A = IndexedBase("A")
pycode(A[i, j])
```

Expected from the issue hint: one subscript expression with indices joined by
comma-space, `A[i, j]`.

V1 status: confirmed. `_print_Indexed` iterates over `expr.indices` in order and
uses `", ".join(...)`. See PO-003.

### F-004: Confirmed - V1 preserves public compatibility

Changed surface: two new printer override methods on `PythonCodePrinter`.

Expected: no public signature changes and no required update to callers or
subclasses.

V1 status: confirmed. `pycode`, `doprint`, constructors, and non-Python printers
are unchanged. `LambdaPrinter` inherits the fix, matching the lambdify use case.
See PO-005.

### F-005: Residual verification caveat - proof is constructed only

Input: the FVK claims in `fvk/pycode-indexed-spec.k`.

Observed: this environment forbids running `kompile`, `kast`, `kprove`, tests,
or Python code.

Expected for full FVK confidence: run the emitted commands and receive `#Top`
from `kprove`.

Status: open verification caveat, not a source-code bug. The source conclusion
does not depend on hidden tests or execution results. See PO-006.

## Open Code Findings

None. The audit found no source-code issue requiring a V2 edit beyond the V1
fix.
