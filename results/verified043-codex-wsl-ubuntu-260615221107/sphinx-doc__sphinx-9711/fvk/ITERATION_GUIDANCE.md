# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged. The FVK audit found that the V1 helper discharges the
public version-ordering intent for documented version strings, including the
reported `0.10.0` versus `0.6.0` witness. The only residual boundary is the
explicit compatibility fallback for invalid version strings, which is outside
the documented semantic version domain and preserves prior behavior.

## Recommended Next Checks

If an execution environment becomes available, run normal unit tests focused on
`needs_extensions` and then, separately, the emitted FVK commands:

```sh
kompile fvk/mini-sphinx-version.k --backend haskell
kast --backend haskell fvk/needs-extensions-spec.k
kprove fvk/needs-extensions-spec.k
```

The K artifacts are constructed for this audit but have not been machine
checked. Keep all tests until machine checking and normal project tests run in a
real environment.

## Future Work Outside This Issue

Other Sphinx version checks can be audited separately if a task asks for that
broader behavior. This FVK pass is limited to the `needs_extensions` observable
from sphinx-doc__sphinx-9711 and the V1 patch in `repo/sphinx/extension.py`.
