# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent,
source inspection, and symbolic reasoning only.

## F-001: Pre-fix skipped middleware poisoned persistent handler state

Classification: code bug, resolved by V1.

Input:

- `load_middleware(is_async=True)`.
- Current downstream handler is async and `handler_is_async == True`.
- A sync-only middleware raises `MiddlewareNotUsed` from its factory.
- A later middleware is selected as async based on `handler_is_async`.

Observed before V1:

- The skipped middleware path assigned `handler =
  self.adapt_method_mode(False, handler, True, ...)` before the factory raised.
- The `except MiddlewareNotUsed` branch continued without updating
  `handler_is_async`.
- The next iteration therefore saw a synchronous wrapper in `handler` but a
  stale async declaration in `handler_is_async`.

Expected:

- A middleware that is not used must be removed from the middleware process and
  leave no persistent chain state for later middleware.

V1 status:

- Fixed. `adapted_handler` is local to the factory call and discarded when
  `MiddlewareNotUsed` is raised.

Linked proof obligations: PO-02, PO-03, PO-06.

## F-002: V1 preserves successful middleware installation semantics

Classification: confirmation, no new code change.

Input:

- A valid middleware factory returns a non-`None` instance.

Observed in V1:

- The factory receives the mode-adapted callable via `adapted_handler`.
- After successful return, the code appends process hooks as before.
- The persistent `handler` is then set to
  `convert_exception_to_response(mw_instance)`, and `handler_is_async` is set
  to `middleware_is_async`.

Expected:

- Used middleware should contribute exactly one wrapped middleware instance to
  the chain and advance the persistent mode to the selected middleware mode.

V1 status:

- Confirmed. The V1 temporary variable does not change the success path's
  persistent transition.

Linked proof obligations: PO-02, PO-04.

## F-003: Error branches remain outside the reported bug and preserve the publish guard

Classification: confirmation, no new code change.

Input:

- A middleware has neither sync nor async capability, or a factory returns
  `None`.

Observed in V1:

- Invalid capabilities still raise `RuntimeError` before adaptation.
- `None` factories still raise `ImproperlyConfigured`.
- `_middleware_chain` remains assigned only after the full loop and final
  top-level adaptation.

Expected:

- Existing initialization error behavior should remain unchanged and should not
  publish a partial chain as initialized.

V1 status:

- Confirmed. V1 does not alter these branches.

Linked proof obligations: PO-05, PO-07.

## F-004: Constructed proof requires later machine checking

Classification: proof capability gap, not a code bug.

Input:

- Any middleware list in the modeled domain.

Observed here:

- The proof is constructed over an abstract mini semantics and no `kompile`,
  `kast`, or `kprove` command was run.

Expected:

- A future environment with K installed should run the commands recorded in
  `SPEC.md` and `PROOF.md` and expect all claims to discharge to `#Top`.

V1 status:

- Does not block the source confirmation. It blocks only claims of
  machine-checked proof and any test-removal recommendation.

Linked proof obligations: PO-08.

## F-005: Suggested regression coverage, not applied

Classification: test gap, no test file changes allowed.

Input:

- ASGI middleware loading with a skipped sync-only middleware followed by a
  middleware that would expose stale async metadata.

Observed here:

- The source fix is reasoned about but no tests can be added in this task.

Expected:

- A public regression test should assert that `MiddlewareNotUsed` does not
  mutate persistent handler state in ASGI mode.

V1 status:

- Documented only. The task forbids modifying tests.

Linked proof obligations: PO-03, PO-06.
