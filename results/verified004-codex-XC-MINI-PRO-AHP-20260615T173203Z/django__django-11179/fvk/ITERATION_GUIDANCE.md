# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged. The FVK audit found the originally reported bug as F1 and confirmed that V1 discharges PO1 without introducing compatibility or frame-condition failures.

## Trace

- F1 / PO1: V1's added `setattr(instance, model._meta.pk.attname, None)` is necessary and sufficient for the optimized successful instance-delete path.
- F2 / PO3: Do not add field-update cleanup to the optimized branch; source predicates route those cases to the normal path.
- F3 / PO4 / PO5 / PO6: Do not refactor public APIs, return shapes, queryset delete behavior, or exception ordering. V1 is branch-local and preserves these frames.
- F4: Do not remove tests or claim machine-checked proof confidence until the emitted K commands and Django tests can run in a suitable environment.

## Recommended Next Steps Outside This Session

1. Run the exact K commands in `fvk/PROOF.md` in an environment with K installed.
2. Run the Django deletion regression tests in a normal Django test environment.
3. When test edits are allowed, add a regression test for `instance.delete()` on a dependency-free model asserting `instance.pk is None` after successful deletion.
