# FVK Proof Obligations

Status: constructed, not machine-checked.

## Obligations

PO-1, domain and state abstraction.

For a `caplog` fixture instance during an active test phase, the relevant state
is:

- shared handler level `H`;
- target logger level `G`;
- optional saved handler level `SH`;
- optional saved logger level `SG`.

The initial fixture state before any `set_level()` call is
`state(H0, G0, none, none)`. This abstracts the real implementation's handler
object and per-logger dictionary while preserving the observable level values.

PO-2, first `set_level()` transition.

From `state(H0, G0, none, none)`, calling `set_level(L)` must reach
`state(L, L, some(H0), some(G0))`.

Code evidence:

- `_initial_logger_levels.setdefault(logger, logger_obj.level)` saves `G0`.
- V1's `if self._initial_handler_level is None:
  self._initial_handler_level = self.handler.level` saves `H0`.
- `logger_obj.setLevel(level)` and `self.handler.setLevel(level)` set both
  current levels to `L`.

PO-3, repeated `set_level()` and finalization.

For any later `set_level(L2)` before finalization, the saved values must remain
the first saved values: `state(L2, L2, some(H0), some(G0))`. Finalization from
that state must reach `state(H0, G0, some(H0), some(G0))`.

Code evidence:

- `setdefault` preserves the first saved logger level per logger key.
- The `is None` guard preserves the first saved handler level.
- `_finalize()` restores every saved logger level and, if present, restores the
  saved handler level.

PO-4, no `set_level()` frame condition.

Finalization from `state(H0, G0, none, none)` must leave the modeled levels
unchanged. This avoids introducing a handler write for tests that only inspect
or read captured logs.

PO-5, `at_level()` frame condition.

For any pre-block handler level `H` and logger level `G`, `at_level(L)` must
restore `H` and `G` after block exit, including exceptional exits. Existing code
uses a `finally` block to restore both values; V1 does not edit this path.

PO-6, cross-test shared-handler obligation.

Given pytest reuses one `LoggingPlugin.caplog_handler`, if test `T1` starts
with handler level `H0`, calls `caplog.set_level(L)`, and finalizes, then any
later test `T2` that receives the same handler must observe `H0` unless pytest
explicitly sets another configured level at phase entry. In the issue's default
case `H0 = 0`, so `T2` must observe `0`, not `L`.

PO-7, compatibility obligation.

The fix must not change public method signatures, fixture return shape, captured
record storage, report formatting, live logging APIs, or file logging APIs.

PO-8, honesty obligation.

Because no tests, Python, or K tooling may be run, all proof results are
constructed, not machine-checked. Test deletion is not justified in this pass.

## K Commands To Run Later

These commands were not executed in this session:

```sh
kompile fvk/mini-caplog.k --backend haskell
kast --backend haskell fvk/caplog-restore-spec.k
kprove fvk/caplog-restore-spec.k --definition fvk/mini-caplog-kompiled
```

Expected result after a real machine check: `kprove` returns `#Top` for the
claims in `fvk/caplog-restore-spec.k`.
