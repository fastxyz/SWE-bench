# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged.

## Why No Source Edit Is Justified

1. F1/O1/O4 show that V1 removes the repeated high-DPI multiplication mechanism
   by serializing logical DPI for non-1 device pixel ratios.

2. F2/O2/O5 show that V1 avoids the over-broad alternative of always serializing
   `_original_dpi`, preserving ordinary ratio-1 current DPI changes.

3. F3/O3 show that V1's `__setstate__` transform resync is necessary and
   sufficient for internal consistency after normalized state is loaded.

4. F4/O6 show no public compatibility break in signatures, return shape, or
   virtual dispatch.

## Follow-Up Work

1. Optional proof strengthening: extend the mini-K numeric model from positive
   integers to exact rational or real-like scalars to cover non-integer display
   ratios in a machine-checkable way.

2. Optional test coverage: add or keep a test that simulates
   `fig.canvas._set_device_pixel_ratio(2)`, pickles/unpickles the figure, and
   checks idempotent DPI and transform consistency. The benchmark forbids
   modifying tests in this task, so no test edit was made.

3. Machine-check the constructed proof later with the commands in
   `fvk/PROOF.md` before relying on test-redundancy recommendations.
