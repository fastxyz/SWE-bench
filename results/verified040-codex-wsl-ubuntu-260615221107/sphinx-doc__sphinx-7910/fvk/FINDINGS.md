# FVK Findings

Status: all code findings in this audit are addressed by V2. The proof is
constructed, not machine-checked.

## F1: V1 fixed the reported decorated-method path

Evidence: I1-I3 and claim C1.

Input class: `what="class"`, `name="__init__"`, docstring present,
`napoleon_include_init_with_doc=True`, wrapper globals do not contain the class,
but `functools.wraps()` preserves `__module__` and `__qualname__`.

Observed in pre-fix code: class ownership is false because
`obj.__globals__[cls_path]` fails.

Expected: class ownership is true and `_skip_member()` returns `False`.

Status: addressed by V1 and retained in V2 through module+qualname resolution.

## F2: V1 did not explicitly discharge the public class-decorator hint

Evidence: I7 and claim C2.

Input class: a decorated class whose module binding is a wrapper class and whose
standard `__wrapped__` attribute points to the original class defining
`__init__`.

Observed in V1 by static reasoning: module+qualname resolution can find the
wrapper class, but V1 checked only the wrapper's own `__dict__`. If the member
is defined on the wrapped original, ownership remains false.

Expected: a standard wrapped class should be treated as an owner candidate for
the documented member.

Status: addressed in V2 by checking both the resolved class and `unwrap(cls)`.

## F3: V1 dropped the old top-level globals fallback

Evidence: I4, I8, and claim C4.

Input class: a top-level class member for which module+qualname resolution is
not available, but the old `obj.__globals__[cls_path]` lookup would find the
owner.

Observed in V1 by static reasoning: module lookup failure made ownership false.

Expected: preserve old behavior when the module path cannot be resolved and the
class path is not dotted.

Status: addressed in V2 by falling back to `obj.__globals__[cls_path]` only for
top-level class paths after module+qualname resolution fails.

## F4: Non-owner and disabled-config paths must remain default

Evidence: I5-I6 and claims C5-C8.

Input class: no owner candidate, disabled include setting, module settings not
enabled, public member, or `__weakref__`.

Observed in V2 by static reasoning: these paths return `None` through the final
fall-through.

Expected: no force include; autodoc keeps its default skip decision.

Status: addressed by preserving the original decision gates.

## F5: Real Python object semantics are outside the mini model

Evidence: proof scope in `fvk/SPEC.md`.

The K model abstracts import lookup, descriptors, `hasattr`, `__dict__`, and
`unwrap` into owner booleans. That is sufficient to audit the decision logic and
the V1/V2 ownership obligations, but it is not a full Python semantics.

Status: residual integration-test obligation. No further source change is
justified by this finding.
