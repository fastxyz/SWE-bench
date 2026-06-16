# Intent Spec

This file records public intent before accepting V1 behavior as correct.

1. `_spectral_helper` must correct PSD spectrum scaling for real windows with
   negative coefficients.
2. The affected path is `mode == "psd"` with `scale_by_freq=False`.
3. Spectrum scaling must use the coherent gain of the window:
   `sum(window)**2` for real windows.
4. Density scaling with `scale_by_freq=True` must remain based on the squared
   window norm, `sum(abs(window)**2)`, with the existing `Fs` factor.
5. Positive-window behavior is a compatibility frame condition because old and
   new denominators coincide when every coefficient is nonnegative.
6. Public APIs and wrappers must keep their signatures, defaults, and return
   shapes.
7. Complex window semantics are not specified well enough in the public issue
   to require a production change in this pass.

