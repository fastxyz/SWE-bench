# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO1 - Raw Kwargs Reach `get_context_data()`

Intent: I1, I2. Evidence: E1-E3.

Precondition: `TemplateView.get()` receives URL kwargs map `KW`.

Postcondition: the kwargs map observed by `get_context_data()` is exactly `KW`;
no value in `KW` has been replaced by `lazy(K, V)` before the virtual call.

Constructed K claim: `GET-FORWARDS-RAW-KWARGS` in
`fvk/templateview-spec.k`.

V1 discharge: `TemplateView.get()` calls `self.get_context_data(**kwargs)`
directly. The helper call occurs only after that call returns.

## PO2 - Final Context Keeps Deprecated URL Kwargs Working

Intent: I3, I4. Evidence: E5-E8.

Precondition: `get_context_data(**KW)` returns context `C`.

Postcondition: the rendered response context is `wrapCtx(C, KW)`, where
unchanged URL kwarg entries become lazy warning wrappers and other entries are
preserved.

Constructed K claim: `GET-RENDERS-WRAPPED-CONTEXT`.

V1 discharge: `TemplateView.get()` calls
`_wrap_url_kwargs_with_deprecation_warning(context, kwargs)` before
`render_to_response(context)`.

## PO3 - Do Not Overwrite Removed or Replaced Context Entries

Intent: I5. Evidence: E5, E7, representative overrides.

Precondition: URL kwargs map contains `K -> V`; returned context `C` either
lacks `K` or contains `K -> V2` with `V2 is not V`.

Postcondition: wrapping does not add `K` when it is absent and does not replace
`V2`.

Constructed K claim: `DO-NOT-WRAP-REMOVED-OR-REPLACED`.

V1 discharge: helper condition is `if key not in context or context[key] is not
value: continue`.

## PO4 - Warning Timing Stays Lazy

Intent: I4. Evidence: E6-E8.

Precondition: final context entry remains an unchanged URL kwarg.

Postcondition: warning is emitted when the final context value is forced, not
before `get_context_data()` runs.

Constructed K support: the `lazy(K, V)` value is introduced by `wrapCtx` after
the modeled `get_context_data` step.

V1 discharge: `SimpleLazyObject` is still used for final context entries, but
only after context construction.

## PO5 - Public API Compatibility

Intent: preserve public method and override compatibility.

Precondition: public callers and subclasses use `TemplateView.get()` and
`get_context_data(self, **kwargs)` as before.

Postcondition: no public signature changes and no new virtual-dispatch argument
is introduced.

V1 discharge: only a private helper signature changed, and the allowed source
scan found no external source callsites.

## PO6 - ORM Lazy Support Is Out of Scope

Intent: I6. Evidence: E4.

Precondition: user passes a `SimpleLazyObject` directly to ORM filtering outside
this `TemplateView` path.

Postcondition: this fix makes no guarantee that the ORM accepts it.

V1 discharge: no ORM files were edited.

## Commands Not Executed

```sh
kompile fvk/mini-templateview.k --backend haskell
kast --backend haskell fvk/templateview-spec.k
kprove fvk/templateview-spec.k
```
