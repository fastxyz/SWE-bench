# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and the constructed proof obligations; no tests or K
tools were run.

## F1: Pre-V1 `_make_subclass` rejected in-domain generic keys

- Classification: code bug fixed by V1.
- Evidence: PROBLEM says `_make_subclass` attempted to concatenate a `str` to a
  `TypeVar`; the expected behavior is that docs still build when generics are
  involved.
- Input: a mocked class parameterized with a `TypeVar`, modeled as
  `mockGetItem("dummy.SomeClass", "SomeClassMock", TypeVarName("T"))`.
- Pre-V1 observed behavior: `_make_subclass` used `module + "." + name` while
  `name` was not a string, producing the reported `TypeError`.
- Expected behavior: normalize the key to a string before display-name
  concatenation and `type()` construction.
- Status: discharged by PO1, PO2, PO4, and PO5.

## F2: Existing string-name mock behavior must be preserved

- Classification: compatibility obligation.
- Evidence: public mock tests assert dotted repr strings such as
  `mocked_module.some_attr`.
- Input: `_make_subclass("some_attr", "mocked_module", superclass)`.
- V1 observed behavior by static inspection: `_make_subclass_name("some_attr")`
  returns the original string; dotted display construction remains
  `mocked_module.some_attr`.
- Expected behavior: no change for existing string names.
- Status: discharged by PO3.

## F3: Name normalization needs a side condition for non-string `__name__`

- Classification: proof side condition handled by V1.
- Evidence: mocked objects fabricate arbitrary attributes through `__getattr__`;
  blindly trusting `getattr(obj, "__name__")` could return a mock object rather
  than a string.
- Input: a non-string key whose `__name__` lookup returns a non-string object.
- Expected behavior: do not feed a non-string `__name__` to display-name
  concatenation or `type()`.
- V1 behavior: checks `isinstance(name_attr, str)` before using it; otherwise
  falls back to `repr(name)`.
- Status: discharged by PO1 and PO6.

## F4: No unhandled public compatibility issue found

- Classification: compatibility confirmation.
- Evidence: callsite search found `_make_subclass` used internally in
  `mock.py`; `_MockObject` is re-exported, but the changed runtime behavior only
  widens accepted subscript keys.
- Expected behavior: no public arity, dispatch, or return-shape break.
- Status: discharged by PO7.

## Open Findings

None. The audit found no source-level defect requiring a V2 edit beyond V1.
