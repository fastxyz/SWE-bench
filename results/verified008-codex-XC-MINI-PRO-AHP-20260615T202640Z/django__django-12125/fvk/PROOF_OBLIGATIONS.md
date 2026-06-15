# FVK Proof Obligations

Status: constructed, not machine-checked. The obligations are written as a
reduced K-style model of the serializer branch; no K tooling was run.

## Abstract Model

Represent a class object by:

`ClassRef(module, name, qualname, is_builtin, is_models_model, is_none_type)`.

Represent serializer output by:

`Serialized(code_string, imports)`.

The audited implementation branch is:

```text
if value is models.Model:
    return Serialized("models.Model", {})
if value is type(None):
    return Serialized("type(None)", {})
if value.__module__ == "builtins":
    return Serialized(value.__name__, {})
return Serialized(value.__module__ + "." + value.__qualname__,
                  {"import " + value.__module__})
```

## K-Style Claims

PO-001: Routing obligation.

For any value `V` where `isinstance(V, type)` is true,
`serializer_factory(V)` returns `TypeSerializer(V)`.

Provenance: SPEC I-003; source route in `serializer_factory()`.

PO-002: Nested importable class obligation.

```text
claim serializeType(ClassRef(M, N, Q, false, false, false))
  => Serialized(M + "." + Q, {"import " + M})
requires M =/= "builtins"
     and Q contains "."
     and Q does not contain "<locals>"
```

Provenance: SPEC I-001, I-002, I-003.

PO-003: Top-level class preservation obligation.

```text
claim serializeType(ClassRef(M, N, N, false, false, false))
  => Serialized(M + "." + N, {"import " + M})
requires M =/= "builtins"
```

Provenance: SPEC I-004.

PO-004: Builtin class preservation obligation.

```text
claim serializeType(ClassRef("builtins", N, Q, true, false, false))
  => Serialized(N, {})
```

Provenance: SPEC I-004.

PO-005: `models.Model` special-case preservation obligation.

```text
claim serializeType(ClassRef(_, _, _, false, true, false))
  => Serialized("models.Model", {})
```

Provenance: SPEC I-004.

PO-006: `type(None)` special-case preservation obligation.

```text
claim serializeType(ClassRef(_, _, _, false, false, true))
  => Serialized("type(None)", {})
```

Provenance: SPEC I-004.

PO-007: Enum class route obligation.

For any enum class object `E`, `isinstance(E, type)` is true and PO-001 routes it
to PO-002/PO-003 rather than to `EnumSerializer`.

Provenance: SPEC I-002, I-003; FINDINGS F-004.

PO-008: Adjacent serializer frame obligation.

`Field.deconstruct()` and `EnumSerializer.serialize()` already use
`__qualname__`; the proof for V1 does not require changing their behavior.

Provenance: SPEC I-005; FINDINGS F-004, F-005.

## Commands To Machine-Check In A Future K Environment

No commands were executed in this benchmark. A future full K artifact for this
reduced model would be checked with commands of this shape:

```sh
kompile fvk/mini-python-serializer.k --backend haskell
kast --backend haskell fvk/django-serializer-spec.k
kprove fvk/django-serializer-spec.k
```

Expected outcome if the reduced K files exactly encode the obligations above:
`#Top` for PO-001 through PO-008.
