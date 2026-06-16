# Formal Spec English

Status: constructed, not machine-checked.

## POST-PROCESS-SUCCESS

For any finite initial event list and finite repeat-pass event list with no
exceptions and no max-pass failure, `emitPostProcess()` first emits the
non-adjustable successful initial-pass outputs, stores adjustable outputs by
original path, updates those stored adjustable outputs through each repeat pass,
and finally emits the stored adjustable outputs once per original path.

English result: successful public output contains no duplicate original paths.
Adjustable originals use their final stored result, so intermediate adjustable
pass results are hidden.

## POST-PROCESS-FIRST-PASS-ERROR

If an exception event appears during the initial pass, `emitPostProcess()` emits
the non-adjustable successes that occurred before the exception, emits the
exception, and stops. Deferred adjustable successes are not flushed.

English result: exception tuples remain immediate failure signals.

## POST-PROCESS-REPEAT-PASS-ERROR

If an exception event appears during a repeat pass, `emitPostProcess()` emits the
non-adjustable successes from the initial pass, emits the repeat-pass exception,
and stops. Deferred adjustable successes are not flushed.

English result: exception tuples remain immediate failure signals even after
some adjustable results have been buffered.

## POST-PROCESS-MAX-ERROR

If all modeled repeat passes are consumed and the max-pass failure flag is set,
`emitPostProcess()` emits the non-adjustable successes from the initial pass,
then emits the existing `All` failure and stops. Deferred adjustable successes
are not flushed.

English result: max-pass failure is still reported as the existing public error
and intermediate adjustable results are not exposed as successful post-processed
files.

## Compatibility Claim

All emitted public items are still triples with original name, processed name or
`None`, and processed status or exception. No public method signature is changed.
