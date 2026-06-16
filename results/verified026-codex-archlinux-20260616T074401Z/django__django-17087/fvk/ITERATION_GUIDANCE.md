# Iteration Guidance

Status: constructed from FVK findings and proof obligations.

## Decisions

D-1. Keep the V1 `__qualname__` core fix.

Rationale: F-001 and PO-1 show that the issue's expected migration path requires
the bound class's qualified name. PO-3 shows this preserves top-level classmethod
serialization because `__qualname__ == __name__` for top-level classes.

D-2. Add a local-scope guard for class-bound methods.

Rationale: F-002 and PO-2 show that V1 would otherwise emit `<locals>` in a
migration path for local class-bound methods. Existing local-function behavior
rejects such callables, so V2 aligns the class-bound branch with the same
importability rule.

D-3. Move the lambda rejection before the class-bound method branch.

Rationale: F-003 and PO-4 show the existing lambda rule was bypassed by
class-bound callables. V2 makes the rejection uniform while preserving the same
error message.

D-4. Leave the remaining function serializer logic unchanged.

Rationale: F-004 and PO-5 frame the non-class-bound branches. There is no public
intent evidence requiring broader behavior changes, and unnecessary edits would
increase compatibility risk.

## Next Checks

When an execution environment is available, run the normal Django migration
writer tests and add focused coverage for:

- nested importable classmethod defaults;
- local class-bound methods raising `ValueError`;
- class-bound lambda callables raising the existing lambda `ValueError`;
- unchanged top-level classmethod serialization.

Do not remove any tests unless the K commands in `fvk/PROOF.md` are run and
return `#Top`.
