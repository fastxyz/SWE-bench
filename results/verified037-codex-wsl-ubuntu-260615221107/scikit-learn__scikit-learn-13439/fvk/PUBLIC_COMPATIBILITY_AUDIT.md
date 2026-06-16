# Public Compatibility Audit

## Changed public symbol

`sklearn.pipeline.Pipeline.__len__` is newly added.

## Signature and dispatch

The method has the Python data-model signature `__len__(self)` and does not add
arguments to any existing public method. No existing virtual dispatch call is
changed.

## Public callsites and overrides

No existing source callsites need to be updated because this is a new data-model
method. No subclass override compatibility issue was found in the audited source
paths; adding the method to `Pipeline` does not require subclasses to accept new
arguments or return a different shape from an existing method.

## Truthiness compatibility

Adding `__len__` can affect `bool(obj)` in Python. For valid `Pipeline`
instances, construction requires a non-empty `steps` sequence with a final
estimator, so `len(pipe) >= 1` and `bool(pipe)` remains true. If a user later
mutates `steps` to an empty sequence, `bool(pipe)` may become false, but that
state is outside the documented valid construction contract and the method body
still returns the actual length.

## Verdict

No public compatibility issue blocks keeping V1.
