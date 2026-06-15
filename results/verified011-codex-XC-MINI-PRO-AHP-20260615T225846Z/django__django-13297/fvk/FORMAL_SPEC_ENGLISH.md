# Formal Spec English

Claim `GET-FORWARDS-RAW-KWARGS`: when `TemplateView.get()` receives URL kwargs
`KW`, the modeled `get_context_data()` call observes exactly `KW`, not a map
where values have been wrapped.

Claim `GET-RENDERS-WRAPPED-CONTEXT`: when `get_context_data(**KW)` returns
context `C`, the response context is `wrapCtx(C, KW)`.

Definition `wrapCtx(C, KW)`: for every URL kwarg key `K` with value `V`, if `K`
is present in `C` and `C[K]` is the same value `V`, replace `C[K]` with
`lazy(K, V)`; otherwise leave `C` unchanged for that key.

Claim `WRAP-UNCHANGED-ENTRY`: an unchanged final context URL kwarg becomes a
lazy warning wrapper.

Claim `DO-NOT-WRAP-REMOVED-OR-REPLACED`: missing entries remain missing and
replacement entries remain replacement entries.
