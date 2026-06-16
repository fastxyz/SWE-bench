# Formal Spec English

Status: constructed for FVK audit; not machine-checked.

This file paraphrases the K claims in `outputwrapper-spec.k`.

## Claim FLUSH-DELEGATES

For any wrapped stream `out` whose stream state says a flush method exists, executing
`wrapper(out).flush()` calls that stream's flush behavior exactly once. The stream's
buffered output becomes visible, its buffer becomes empty, its flush count increases by
one, and the wrapper returns the underlying flush return value.

## Claim FLUSH-NO-METHOD-NOOP

For any wrapped stream `out` whose stream state says no flush method exists, executing
`wrapper(out).flush()` returns `none` and leaves the stream state unchanged.

## Claim PARTIAL-WRITE-THEN-FLUSH

For any wrapped stream `out` with a flush method, executing a partial write of `N`
output units and then executing `wrapper(out).flush()` makes the previous visible output
plus the existing buffer plus those `N` new units visible, empties the buffer, increments
the flush count once, and returns the underlying flush return value.

## Frame Conditions

The formal claims do not change the semantics of `OutputWrapper.write()`, `isatty()`,
`style_func`, `BaseCommand.__init__()`, or `BaseCommand.execute()`. They model only the
new explicit `flush()` behavior and the partial-write/flush ordering needed by
`migrate`.

## Side Conditions

The model assumes nonnegative buffered and visible output counters, nonnegative flush
counts, and a nonnegative partial-write size. These are measurement-domain assumptions
for an abstract output model, not restrictions on Django user data.
