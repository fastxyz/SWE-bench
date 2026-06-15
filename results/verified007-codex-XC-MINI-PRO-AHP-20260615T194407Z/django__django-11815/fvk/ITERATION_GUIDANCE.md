# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Code Decision

V1 stands unchanged. The audit found that the current source change discharges
the public issue's required behavior for named enum members:

- PO2 proves the output form is name lookup.
- PO3 proves the generated expression is independent of translated enum values.
- PO4 proves the expression reconstructs the enum member by name.
- PO5 proves the remaining import set is sufficient.

No additional production-code edit is justified by the FVK findings.

## Test Guidance

Do not modify tests in this benchmark. In a normal Django patch, update the
public enum serializer expectations called out by F2 from value constructors to
name lookups, and add a regression test for an enum member whose value is a lazy
translation object.

Keep tests for `models.Choices` serialization, because F3 confirms that behavior
is intentionally outside this fix.

No test is recommended for removal. The proof is constructed, not
machine-checked, and the task forbids running test or K tooling.

## Follow-Up Questions

- Should Django explicitly document enum migration serialization as supporting
  only named enum members that are importable by module and class name?
- Should unsupported enum pseudo-members without stable names raise a clearer
  serialization error? The public issue does not require that change.

## Next Iteration

If further work were allowed, the next conventional patch iteration should focus
only on public tests and documentation around enum serialization. The production
fix itself should remain the V1 implementation unless new public intent expands
the supported domain beyond named enum members.
