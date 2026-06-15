# Formal Spec In English

## Claim `FIELD-DEEPCOPY-COPY-ERRORS`

Given a heap containing a source field object `F`, where `F` points to an
existing widget object `WO`, an existing error_messages object `EO`, and an
existing validators-list object `VO`, and given a fresh allocation counter `N`
greater than all of those existing object ids:

Running `deepcopyField(F)` returns the new field object id `N`.

The source field and its original widget, error_messages, and validators objects
remain present and unchanged.

The copied field `N` points to fresh object ids:

- `N + 1` for the copied widget,
- `N + 2` for the copied error_messages mapping,
- `N + 3` for the copied validators list.

The copied error_messages object has the same abstract payload as the source
error_messages object but a different object identity. Therefore mutating the
copied mapping cannot mutate the source mapping by aliasing.

## Side conditions

The source field, widget, error_messages, and validators ids are distinct and
already allocated before the call. The allocator counter `N` is fresh.

## Loops and termination

There are no loops or recursive calls in the modeled method. The constructed
proof is a partial-correctness proof and was not machine-checked.
