# FVK Proof

Status: constructed, not machine-checked.

## Claim

For every named enum member `E` in the specified domain:

```text
EnumSerializer(E).serialize()
  reaches
("%s.%s[%r]" % (E.__class__.__module__, E.__class__.__name__, E.name),
 {"import %s" % E.__class__.__module__})
```

This is the `ENUM-SERIALIZE` claim represented in
`fvk/enum-serializer-spec.k`.

## Symbolic Execution

Initial symbolic state:

```text
self.value = E
enum_class = E.__class__
module = enum_class.__module__
```

V1 executes the straight-line return:

```python
return "%s.%s[%r]" % (
    module,
    enum_class.__name__,
    self.value.name,
), {'import %s' % module}
```

Substitution gives:

```text
serialized_expression =
  E.__class__.__module__ + "." +
  E.__class__.__name__ + "[" +
  repr(E.name) + "]"

imports = {"import " + E.__class__.__module__}
```

There are no loops or branches in this target, so no circularity claim is
needed. The proof is a direct reachability proof by one semantic return step and
consequence over string formatting.

## Value-Independence Argument

The old implementation symbolically evaluated:

```python
serializer_factory(E.value).serialize()
```

and inserted the resulting value expression into:

```python
EnumClass(<serialized value>)
```

For a lazy translation value, `serializer_factory()` first coerces a `Promise` to
`str(value)`, so the generated migration can contain a language-dependent string.

V1 has no occurrence of `E.value` in either the generated expression or the
import set. Therefore changing the active language or rendered translation of
`E.value` cannot change the generated enum lookup expression.

## Reconstruction Argument

By the domain precondition, `E.name` is a valid member name for `E.__class__`.
Python enum class lookup by name returns that member:

```python
E.__class__[E.name] is E
```

The generated migration expression uses exactly this lookup form. Therefore the
serialized expression reconstructs the enum member by stable name rather than by
mutable value.

## Adequacy Gate

| Formal statement | Intent evidence | Result |
| --- | --- | --- |
| Use `E.name` in bracket lookup. | E1, E2, E4 in `SPEC.md`. | Pass. |
| Do not serialize `E.value`. | E3 in `SPEC.md`. | Pass. |
| Keep `models.Choices` value serialization separate. | E5 and public choices tests. | Pass. |
| Existing value-constructor enum tests are authoritative. | Conflicts with E1-E4. | Fail as SUSPECT; see F2. |

The proof matches the public issue intent for the specified named-member domain.
No adequacy failure blocks the decision that V1 stands.

## Non-Executed Machine-Check Commands

These are the commands to run in an environment with K installed. They were not
run in this benchmark session.

```sh
kompile fvk/mini-python-enum-serializer.k --backend haskell
kast --backend haskell fvk/enum-serializer-spec.k
kprove fvk/enum-serializer-spec.k
```

Expected result for the constructed mini semantics: `kprove` discharges the
straight-line `ENUM-SERIALIZE` claim to `#Top`.

## Residual Risk

This is a partial-correctness proof over a mini serializer model, not a full
Python-in-K proof of Django. It does not prove termination separately, though the
audited function is straight-line. It does not justify deleting tests because the
proof is constructed only.
