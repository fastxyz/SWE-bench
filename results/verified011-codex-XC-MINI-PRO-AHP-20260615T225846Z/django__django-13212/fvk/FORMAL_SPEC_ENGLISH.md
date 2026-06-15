# Formal Spec English

## Claim C1

For any validator in the audited validator family and any submitted value,
if that validator rejects the value, the validation result is a
`ValidationError`-like error with the same message and code as before and a
params map equal to the validator's existing params updated with
`value -> submitted value`.

## Claim C2

The submitted value used for the `value` param is the original top-level
argument to the validator. It is not a transformed URL, a parsed email domain,
an IPv6 literal fragment, a file extension, or a key-set difference.

## Frame Condition C3

The proof does not change or verify each validator's validity predicate. It
treats validity as a frame condition and checks only the error params shape on
invalid paths.
