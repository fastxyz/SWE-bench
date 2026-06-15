# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO1: Dispatch Scope

For any value handled by `serializer_factory()`, `models.Choices` members must
continue to dispatch to `ChoicesSerializer` before `enum.Enum` reaches
`EnumSerializer`.

Evidence: serializer registry order in `serializer.py`.

Result: discharged by inspection. V1 does not change registry order or
`ChoicesSerializer`.

## PO2: Name-Based Output Form

For a named enum member `E`, `EnumSerializer.serialize(E)` must return an
expression of the form:

```python
<module>.<EnumClass>[<repr(E.name)>]
```

not:

```python
<module>.<EnumClass>(<serialized E.value>)
```

Evidence: problem statement and public hint.

Result: discharged by V1 line in `EnumSerializer.serialize()`.

## PO3: Independence From Enum Value

The serialized expression and import set must not require serialization of
`E.value`. In particular, lazy translation objects in `E.value` must not be
converted to a language-dependent string by this path.

Evidence: issue failure mode involving translated values.

Result: discharged by V1 because it does not call
`serializer_factory(self.value.value)`.

## PO4: Reconstruction Correctness

Under the domain precondition that `E.name` is a valid member name in `E`'s enum
class, evaluating:

```python
<module>.<EnumClass>[<repr(E.name)>]
```

reconstructs `E` by enum member lookup.

Evidence: Python enum name lookup convention and public desired output form.

Result: discharged by the constructed proof for named enum members.

## PO5: Import Sufficiency

The import set returned by `EnumSerializer.serialize()` must include the enum
class module and need not include imports for the enum value.

Evidence: generated expression mentions only `<module>`, `<EnumClass>`, and
`E.name`.

Result: discharged by V1 returning `{'import %s' % module}`.

## PO6: Public Compatibility

The fix must preserve the serializer API shape and avoid unrelated behavior
changes.

Evidence: `MigrationWriter.serialize()` consumes `(string, imports)` pairs from
serializer classes.

Result: discharged. The method signature and return shape are unchanged.
`models.Choices` behavior is unchanged by PO1.

## PO7: Adequacy Against Full Public Intent

The formal claim must cover the behavior the issue actually requires: ordinary
named enum members used as migration-serialized values/defaults.

Evidence: problem example and public hint both use a named enum member,
`Status.GOOD`, and desired lookup `Status['GOOD']`.

Result: discharged. Pseudo-members without a stable member name are outside the
publicly evidenced domain and are not used to justify code changes.

## PO8: Honesty Gate

The audit must not claim machine-checked proof or test redundancy because no
execution environment is available and the task forbids running tests or K
tooling.

Evidence: task no-exec rule and FVK honesty gate.

Result: discharged by labeling artifacts "constructed, not machine-checked" and
by making no test-removal recommendation.
