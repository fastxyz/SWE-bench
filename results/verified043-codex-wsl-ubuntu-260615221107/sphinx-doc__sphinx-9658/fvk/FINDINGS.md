# FVK FINDINGS

F-001: Resolved code bug: mocked base loses its final class-name component.

Input: a documented class inheriting a mocked base represented by module `torch.nn` and name `Module`, with autodoc `show-inheritance` enabled.

Observed pre-V1 behavior: `Bases: torch.nn.` because `ClassDocumenter` used `__orig_bases__`, the original mock instance had `__qualname__ == ""`, and `restify()` rendered `__module__ + "." + __qualname__`.

Expected behavior: `Bases: torch.nn.Module`, per IS-1 and E-2.

Resolution: V1 sets the mock instance `__qualname__` from the generated mock class `__qualname__`. This discharges PO-1 and PO-2.

Status: resolved by existing V1 source change; no further code edit required.

F-002: Rejected alternative: rewriting bases in `ClassDocumenter`.

Input: a class whose `__orig_bases__` contains a mocked base object.

Alternative considered: replace mocked original bases with `base.__class__` in `ClassDocumenter.add_directive_header()` before calling `restify()`.

Reason rejected: the defect is missing metadata on the mock object that autodoc already has to format. Changing the metadata preserves the existing `autodoc-process-bases` event surface and leaves generic-base handling untouched, satisfying PO-3, PO-4, and PO-6 with less blast radius.

Status: no source change beyond V1.

F-003: Compatibility confirmed: mocked annotation and decorator behavior is not changed.

Input: `def func(arg: missing_module.Class)` and mocked decorators such as `@missing_name`.

Expected behavior: annotation output remains `missing_module.Class`; decorated objects remain recoverable by `undecorate()`.

Reasoning: `typing.stringify()` returns `repr(annotation)` for falsy mock objects before using `__qualname__`, and V1 does not change mock falsiness, `__repr__()`, `__sphinx_decorator_args__`, or `undecorate()`.

Status: confirmed by PO-5 and PO-6; no source change required.

F-004: Compatibility confirmed: normal and typing-generic base rendering remain untouched.

Input: non-mocked base classes and typing generic bases such as `List[Union[int, float]]`.

Expected behavior: existing `restify()` and `ClassDocumenter` output remains unchanged.

Reasoning: V1 changes only `_MockObject.__init__()`. It does not alter `ClassDocumenter`, `restify()`, or typing generic branches.

Status: confirmed by PO-4; no source change required.

F-005: Residual proof caveat: constructed, not machine-checked.

Input: the K claims in `fvk/mock-base-spec.k`.

Expected verification status: `kprove mock-base-spec.k` from the `fvk/` directory should reduce the claims to `#Top`.

Actual status in this session: no K commands were run because the task forbids executing K tooling.

Status: residual verification caveat, not a code defect. Keep any existing tests; add targeted tests in a normal development environment.

F-006: Out-of-scope ambiguity: parameterized mocked-base display is not specified by the issue.

Input: a class inheriting a parameterized mocked object such as `missing_module.Base[T]`.

Public intent: the issue requires complete display of mocked class names and gives `torch.nn.Module`; it does not specify the textual form for parameterized mocked bases.

Status: not used to justify V1 correctness. Future work should formalize this separately if a public issue requires it.
