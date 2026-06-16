# Proof Obligations

Status: constructed for audit, not machine-checked.

## PO-1: Distinguish absent `__all__` from explicit empty sequence

Obligation:

- `None` is the only state that means absent/ignored/invalid `__all__`.
- A valid empty list or tuple is an explicit sequence and must not enter the
  absent path.

Source:

- `inspect.getall()` returns `None` when no `__all__` exists and returns the
  valid list/tuple sequence otherwise.
- The issue states that empty `__all__` must be honored.

Discharge:

- V1 uses `self.__all__ is None`.
- K model represents this as `noAll` versus `exports(.Names)`.

Status: discharged by source inspection and claim `EMPTY-ALL-BRANCH`.

## PO-2: Empty explicit sequence enters explicit-`__all__` branch

Obligation:

- For `want_all=True` and `self.__all__ = []`, `get_object_members()` must take
  the explicit sequence branch, not the implicit member branch.

Discharge:

- `[] is None` is false, so V1 enters the `else` branch.
- K claim `EMPTY-ALL-BRANCH` states the same branch selection.

Status: discharged.

## PO-3: Explicit-`__all__` branch marks every non-exported member skipped

Obligation:

- For every module member `m`, if `m.__name__ not in self.__all__`, set
  `m.skipped = True`.

Empty case:

- If `self.__all__ = []`, every member name satisfies the non-membership check.

Discharge:

- Existing loop in `get_object_members()` is reused unchanged.
- K function `markSkipped(.Names, Members)` rewrites every member's skip flag to
  `true`.

Status: discharged by existing code path and claim `EXPLICIT-ALL-BRANCH`.

## PO-4: Forced-skipped members are omitted by default filtering

Obligation:

- In the no-user-override issue scenario, `filter_members()` must omit every
  member whose `ObjectMember.skipped` flag is true.

Discharge:

- Existing code sets `keep = False` for `ObjectMember` instances with
  `obj.skipped`.
- K claim `EMPTY-ALL-FILTER` states that filtering members produced from
  `exports(.Names)` yields `.Members`.

Status: discharged for default skip policy.

## PO-5: Missing or ignored `__all__` behavior is preserved

Obligation:

- When `__all__` is absent, invalid, raises, or intentionally ignored by
  `ignore-module-all`, autodoc should keep using the implicit-member path.

Discharge:

- Those cases leave `self.__all__` as `None`.
- V1 still returns `(True, members)` for `self.__all__ is None`.
- K claim `NO-ALL-BRANCH` captures this frame condition.

Status: discharged.

## PO-6: Public event override compatibility is preserved

Obligation:

- Existing `autodoc-skip-member` event behavior for members not in `__all__`
  must remain available.

Discharge:

- V1 does not return early with an empty member list.
- It reuses the existing explicit-`__all__` forced-skip path, so
  `filter_members()` still reaches the event hook with the same style of skip
  decision as non-empty `__all__`.

Status: discharged by source inspection. Not modeled in the default-output K
claim because the issue reproducer has no event override.

## PO-7: Explicit named member selection is unchanged

Obligation:

- If `want_all=False`, `get_object_members()` should continue to select only
  names requested through `:members: foo,bar`.

Discharge:

- The V1 edit is inside the `if want_all:` branch only.
- K claim `EXPLICIT-MEMBERS-FRAME` records the unchanged branch.

Status: discharged.

## Machine-check commands recorded, not run

The following commands are the intended future machine check:

```sh
cd fvk
kompile mini-python.k --backend haskell
kast --backend haskell autodoc-module-all-spec.k
kprove autodoc-module-all-spec.k
```

They were not executed in this session.
