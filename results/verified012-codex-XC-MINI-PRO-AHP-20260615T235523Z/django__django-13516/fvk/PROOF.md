# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`, or
`kprove` were run.

## Claims Proved

The proof covers three claims in `outputwrapper-spec.k`:

* `FLUSH-DELEGATES`: a wrapper flush delegates to a wrapped stream that supports flush.
* `FLUSH-NO-METHOD-NOOP`: a wrapper flush leaves a stream without flush unchanged.
* `PARTIAL-WRITE-THEN-FLUSH`: a partial write followed by flush makes the partial output
  visible before later output.

There are no loops or recursive calls in this formal target, so no circularity claim is
needed. The proof is partial correctness over the abstract output semantics.

## Proof Sketch

### FLUSH-DELEGATES

Initial state:

```k
<k> wrapper(out).flush() </k>
<streams> out |-> stream(true, B, V, F, R) </streams>
```

with nonnegative counters.

Symbolic execution applies the flush-delegation semantic rule from
`mini-management-output.k`. The rule rewrites the stream to:

```k
stream(true, 0, V +Int B, F +Int 1, R)
```

and rewrites the computation to `R`. This is exactly the post-state in the claim.

### FLUSH-NO-METHOD-NOOP

Initial state:

```k
<k> wrapper(out).flush() </k>
<streams> out |-> stream(false, B, V, F, R) </streams>
```

Symbolic execution applies the no-flush compatibility rule. The computation rewrites
to `none`, and the stream cell is framed unchanged. This is exactly the post-state in
the claim.

### PARTIAL-WRITE-THEN-FLUSH

Initial state:

```k
<k> wrapper(out).writePartial(N) ~> wrapper(out).flush() </k>
<streams> out |-> stream(true, B, V, F, R) </streams>
```

Step 1: apply the partial-write rule. The buffer changes from `B` to `B + N`; visible
output and flush count are unchanged.

Step 2: by transitivity, execute `wrapper(out).flush()` from the intermediate state.
Instantiate `FLUSH-DELEGATES` with buffer `B + N`. The stream rewrites to:

```k
stream(true, 0, V +Int (B +Int N), F +Int 1, R)
```

Associativity of integer addition rewrites this to the claim's postcondition:

```k
stream(true, 0, V +Int B +Int N, F +Int 1, R)
```

This proves the issue-observable ordering: output written before the flush is visible
before later success output.

## Adequacy Gate

`SPEC_AUDIT.md` marks every formal claim as passing against `INTENT_SPEC.md`.
`PUBLIC_COMPATIBILITY_AUDIT.md` found no unhandled callsite, override, signature, or
producer/consumer change. Therefore the constructed proof is adequate for deciding
whether V1 should stand.

## Test Recommendation

No test removal is recommended. The proof is not machine-checked, and the public tests
seen in the audit cover broader management-command stream wiring. A useful future test
would use a custom stream whose `flush()` records calls, then assert that
`OutputWrapper.flush()` delegates and that `migrate` progress callbacks flush after
partial-line output.

## Reproduce the Machine Check Later

These commands were not run:

```sh
cd fvk
kompile mini-management-output.k --backend haskell
kast --backend haskell outputwrapper-spec.k
kprove outputwrapper-spec.k
```

Expected result: `#Top` for the three claims. This expectation is constructed, not
machine-checked.

## Residual Risk

The trusted base is the adequacy of the abstract stream model, the K reachability
framework, and any future machine-checking environment. The model is intentionally
minimal and does not claim to verify all Python `io` behavior; it verifies the specific
delegation and visibility property required by the issue.
