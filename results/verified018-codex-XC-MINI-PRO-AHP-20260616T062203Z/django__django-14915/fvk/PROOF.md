# Constructed Proof

Status: constructed, not machine-checked. No tests, Python code, `kompile`, `kast`, or `kprove` were run.

## What is proved

For every `ModelChoiceIteratorValue(V, O)` whose wrapped value `V` is hashable, the wrapper's hash is `hash(V)`, equality remains value-based, and dictionary membership/getitem using the wrapper reaches the same entry under the ordinary key-equality behavior demonstrated by the issue's integer-key dictionary.

This proves the issue slice: a user `create_option()` override can use `value in {1: ...}` and `{1: ...}[value]` when `value` is a wrapper around `1`.

## Proof sketch

1. Construction: `ModelChoiceIterator.choice(obj)` produces `ModelChoiceIteratorValue(prepare_value(obj), obj)`. The object has two fields, `.value` and `.instance`.

2. Equality: the existing `__eq__()` first unwraps another `ModelChoiceIteratorValue`, then returns `self.value == other`. Therefore equality of wrappers is equality of wrapped prepared values.

3. Hash: V1 adds `__hash__()` returning `hash(self.value)`. Therefore for any hashable `V`, `hash(ModelChoiceIteratorValue(V, O)) == hash(V)`.

4. Hash/equality invariant: if `ModelChoiceIteratorValue(V, O) == K`, then equality reduces to `V == K`. For hashable values obeying Python's hash contract, `hash(V) == hash(K)`. Step 3 gives `hash(W) == hash(K)`.

5. Dictionary membership: Python dictionary lookup first hashes the lookup key. Pre-V1 failed here because the wrapper had `__eq__()` but no `__hash__()`. V1 makes this step defined for hashable `V`. Once the matching hash bucket is reached, the stored key and wrapper compare equal in the integer-key scenario from the issue, so membership returns true. The proof does not claim to override deliberately asymmetric custom-key equality.

6. Dictionary getitem: getitem follows the same hash and equality path as membership, then returns the payload associated with the stored key.

7. Frame: V1 does not alter producer code, widget code, `.value`, `.instance`, `__str__()`, or `__eq__()`. The fix is limited to Python's hash protocol.

There are no loops or recursive functions in the audited change. Termination is not separately proved; the proof assumes the wrapped value's `__hash__()` and `__eq__()` terminate.

## Adequacy check

The formal English claims in `fvk/FORMAL_SPEC_ENGLISH.md` match the intent entries in `fvk/INTENT_SPEC.md`; see `fvk/SPEC_AUDIT.md`. No claim depends only on candidate behavior.

## Exact commands not run

```sh
kompile fvk/mini-python-hash.k --backend haskell
kast --backend haskell fvk/model-choice-iterator-value-spec.k
kprove fvk/model-choice-iterator-value-spec.k
```

Expected machine-check result if the mini semantics is accepted: `#Top` for all claims.

## Test recommendation

No tests were read, modified, executed, or recommended for removal. If machine checking is later performed, focused tests for hash equality and dictionary membership may be considered redundant only after `kprove` returns `#Top`; integration tests around form/widget rendering should be kept.
