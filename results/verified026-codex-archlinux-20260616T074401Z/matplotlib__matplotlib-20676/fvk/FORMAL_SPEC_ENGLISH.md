# Formal Spec English

This paraphrases every nontrivial claim in `span-selector-spec.k`.

## SPAN-HORIZONTAL-INTERACTIVE

Starting from an axes state where the x data limits do not contain the selector
helper coordinate `0`, running the V1 horizontal interactive constructor
terminates after adding one rectangle helper and two line-handle helpers. It
does not change whether `0` is in the x data limits, does not change the y
data-limit state, and preserves any pre-existing x/y autoscale-request flags.

## SPAN-VERTICAL-INTERACTIVE

Starting from an axes state where the y data limits do not contain the selector
helper coordinate `0`, running the V1 vertical interactive constructor
terminates after adding one rectangle helper and two line-handle helpers. It
does not change whether `0` is in the y data limits, does not change the x
data-limit state, and preserves any pre-existing x/y autoscale-request flags.

## SPAN-HORIZONTAL-NONINTERACTIVE

Starting from an axes state where the x data limits do not contain `0`, running
the V1 horizontal noninteractive constructor terminates after adding one
rectangle helper and no handle lines. It does not change whether `0` is in the
x data limits and preserves autoscale-request flags.

## SPAN-V0-BUG-LOCALIZATION

If the legacy horizontal constructor path is modeled as `add_patch` for the
rectangle followed by two `add_line`/`axvline` handle additions, then the
initial helper coordinate `0` enters the x data limits and an x autoscale
request is present. This is a witness for the reported bug, not a desired
postcondition.
