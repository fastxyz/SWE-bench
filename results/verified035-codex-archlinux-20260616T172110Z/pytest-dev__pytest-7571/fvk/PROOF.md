# FVK Proof

Status: constructed, not machine-checked. No K commands, tests, or Python code
were run.

## Claims Proved

The constructed proof covers PO-1 through PO-7:

1. `caplog.set_level()` saves the original handler level and target logger
   level before the first mutation in a fixture instance.
2. Repeated `set_level()` calls do not overwrite those first saved values.
3. Fixture finalization restores both logger and handler levels.
4. Tests that never call `set_level()` do not get a new handler-level write.
5. `at_level()` remains block-scoped.
6. The shared caplog handler therefore cannot carry a prior test's
   `set_level()` level into the next test.
7. Public APIs and call shapes remain unchanged.

## Symbolic Proof Sketch

Use the state abstraction from PO-1:

```text
state(handlerLevel, loggerLevel, savedHandlerLevel, savedLoggerLevel)
```

### First set_level call

Initial fixture state:

```text
state(H0, G0, none, none)
```

The V1 code checks `_initial_handler_level is None`, so it saves `H0`.
The existing logger code uses `setdefault`, so it saves `G0`.
Then both setter calls apply level `L`.

Constructed transition:

```text
setLevel(state(H0, G0, none, none), L)
=> state(L, L, some(H0), some(G0))
```

This discharges PO-2.

### Repeated set_level calls

From:

```text
state(L, L, some(H0), some(G0))
```

a later `set_level(L2)` does not pass the handler `is None` guard and does not
overwrite the logger entry because `setdefault` preserves the first value.
It only changes the current handler and logger levels.

Constructed transition:

```text
setLevel(state(L, L, some(H0), some(G0)), L2)
=> state(L2, L2, some(H0), some(G0))
```

By induction on the finite sequence of `set_level()` calls in one fixture
instance, the saved values remain `H0` and `G0`. This discharges the repeated
call part of PO-3.

### Finalization after set_level

From any state reached after at least one `set_level()` call:

```text
state(Ln, Ln, some(H0), some(G0))
```

`_finalize()` iterates over saved logger levels and restores `G0`. V1 then
checks `_initial_handler_level is not None` and restores `H0`.

Constructed transition:

```text
finalize(state(Ln, Ln, some(H0), some(G0)))
=> state(H0, G0, some(H0), some(G0))
```

This discharges PO-3 and, with the reused-handler fact in PO-6, proves the issue
reproduction's second test sees `0` in the default case rather than `42`.

### Finalization without set_level

If no `set_level()` call occurred, saved values remain absent:

```text
finalize(state(H0, G0, none, none))
=> state(H0, G0, none, none)
```

This discharges PO-4.

### at_level preservation

The existing `at_level()` implementation stores `orig_level` and
`handler_orig_level`, mutates both levels for the block, and restores both in a
`finally` block. V1 does not alter that code. Therefore, for any normal or
exceptional block exit:

```text
atLevel(state(H, G, SH, SG), L)
=> state(H, G, SH, SG)
```

This discharges PO-5.

## Adequacy Gate

The formal English in `fvk/SPEC.md` matches the intent spec:

- The handler restore claim is not implementation-derived; it follows from the
  documentation guarantee and the issue's public reproduction.
- The "first saved value wins" rule is supported by the existing logger restore
  behavior and is required for repeated `set_level()` calls to restore the
  pre-test state.
- Restoring to the observed original handler level, not hard-coded `0`, covers
  both the issue's default case and configured `log_level` cases.
- No public compatibility audit entry is unresolved.

## Machine Check Commands

These commands are emitted for later use and were not run:

```sh
kompile fvk/mini-caplog.k --backend haskell
kast --backend haskell fvk/caplog-restore-spec.k
kprove fvk/caplog-restore-spec.k --definition fvk/mini-caplog-kompiled
```

Expected machine-check outcome: `kprove` returns `#Top`.

## Test Recommendation

Do not remove tests in this pass. The proof is constructed but not
machine-checked, and the user explicitly forbids running tests. Existing tests
around `caplog` should be kept. A useful future public test would assert that a
test after `caplog.set_level(42)` observes `caplog.handler.level == 0` under the
default logging configuration.

## Residual Risk

The proof is partial correctness over the modeled state machine. It does not
prove the entire pytest logging plugin, test scheduling, Python exception
semantics, or termination. It also depends on the adequacy of the abstraction
that the issue-relevant observable is fully determined by handler and logger
levels.
