# FVK Notes

## Decision Summary

V1 stands unchanged. The FVK audit found the original source change sufficient for the public issue and did not justify any additional production-code edits.

## Decisions and Traceability

D-1: Kept the V1 `_MockObject.__init__()` change.

Trace: `fvk/FINDINGS.md` F-001; `fvk/PROOF_OBLIGATIONS.md` PO-1, PO-2, PO-3.

Reason: the issue's failing observable is produced when `ClassDocumenter` formats a mocked original base from `__orig_bases__`. V1 gives that mock instance the generated class qualname, so `restify()` can render `torch.nn.Module` instead of `torch.nn.`.

D-2: Did not edit `ClassDocumenter.add_directive_header()`.

Trace: `fvk/FINDINGS.md` F-002 and F-004; `fvk/PROOF_OBLIGATIONS.md` PO-4.

Reason: changing the mock metadata fixes the source of the missing name while preserving the existing base-selection flow, `autodoc-process-bases` event, normal base rendering, and generic-base rendering.

D-3: Did not add a mock-specific branch to `sphinx.util.typing.restify()`.

Trace: `fvk/FINDINGS.md` F-001 and F-002; `fvk/PROOF_OBLIGATIONS.md` PO-1 and PO-2.

Reason: once mock instances expose correct `__module__` and `__qualname__`, the existing generic `restify()` behavior is adequate. A special branch would duplicate mock naming semantics in the typing utility.

D-4: Did not change annotation, decorator, or `ismock()` code paths.

Trace: `fvk/FINDINGS.md` F-003; `fvk/PROOF_OBLIGATIONS.md` PO-5 and PO-6.

Reason: mocked annotations still stringify through the falsy-object `repr()` branch, and V1 does not change decorator argument storage, mock markers, or generated-class MRO shape.

D-5: Recorded but did not act on parameterized mocked-base display.

Trace: `fvk/FINDINGS.md` F-006.

Reason: the public issue requires complete display for mocked class bases such as `torch.nn.Module`; it does not specify the textual contract for parameterized mocked bases like `Base[T]`. That ambiguity should be handled only if future public intent requires it.

D-6: Did not run tests, Python, or K tooling.

Trace: `fvk/FINDINGS.md` F-005; `fvk/PROOF_OBLIGATIONS.md` "Machine-Check Commands"; `fvk/PROOF.md` "Residual Risk".

Reason: the task explicitly forbids execution. The proof is therefore labeled constructed, not machine-checked, and no test-removal recommendation was made.

## Artifacts Produced

Required markdown artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Formal core artifacts:

- `fvk/mini-sphinx-mock.k`
- `fvk/mock-base-spec.k`

No source files were edited during the FVK pass beyond the existing V1 change.
