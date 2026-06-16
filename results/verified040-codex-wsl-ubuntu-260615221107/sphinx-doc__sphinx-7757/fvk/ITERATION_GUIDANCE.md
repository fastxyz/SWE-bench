# Iteration Guidance

Status: constructed for audit; not machine-checked.

## Decision

V1 stands unchanged.

Reason:

- `fvk/FINDINGS.md` F-001 is resolved by the V1 alignment change.
- `fvk/FINDINGS.md` F-002 confirms the changed algorithm matches the formal
  intent for the full default-alignment family in scope.
- `fvk/FINDINGS.md` F-003 confirms public API compatibility.
- `fvk/PROOF_OBLIGATIONS.md` PO-001 through PO-008 are discharged by constructed
  proof or static frame proof.

## Next Code Change

None. Additional source edits would be refactoring rather than repair, and the
task asks for a minimal targeted fix.

## Suggested Test Additions

Do not modify tests in this benchmark task. For the public project suite, add:

```python
sig = inspect.signature_from_str('(a, b=0, /, c=1)')
assert sig.parameters['b'].kind == Parameter.POSITIONAL_ONLY
assert sig.parameters['b'].default == '0'
assert sig.parameters['c'].default == '1'
```

Also add or keep a Python-domain rendering test proving the default is visible
in the rendered `py:function` signature.

## Machine-Check Follow-Up

When an execution environment exists, run:

```sh
kompile fvk/mini-signature-parser.k --backend haskell
kast --backend haskell fvk/signature-from-str-spec.k
kprove fvk/signature-from-str-spec.k
```

Only after `kprove` returns `#Top` should any test-redundancy recommendation be
treated as machine-verified.
