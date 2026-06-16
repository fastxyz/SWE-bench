# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
executed.

## Summary

No open production-code bug was found in V1. The FVK audit confirms that V1
addresses the two public root causes: missing repeated-splitter `__repr__` and
missing `cvargs` lookup for `n_splits`.

## Findings

F1. Resolved: repeated splitters lacked a repr implementation.

- Evidence: `benchmark/PROBLEM.md` shows `repr(RepeatedKFold())` producing
  `<sklearn.model_selection._split.RepeatedKFold object at ...>`.
- Expected: constructor-like repeated splitter repr.
- V1 status: `_RepeatedSplits.__repr__` delegates to `_build_repr(self)`.
- Related obligations: O1, C1.
- Classification: code bug fixed by V1.

F2. Resolved: adding only `__repr__` would still render `n_splits=None`.

- Evidence: public hint states `n_splits` is stored in `cvargs`, not as a class
  attribute.
- Concrete input: default `RepeatedKFold()` state with `cvargs["n_splits"] = 5`.
- Expected: repr includes `n_splits=5`.
- V1 status: `_build_repr` uses a sentinel to detect absent direct attributes
  and then falls back to `self.cvargs`.
- Related obligations: O2, O3, O6, O7, C2, C3.
- Classification: code bug fixed by V1.

F3. Reviewed: parameter-order evidence differs between the issue sample and the
project convention.

- Evidence for constructor-order sample: `benchmark/PROBLEM.md` expected block
  lists `n_splits=5, n_repeats=10, random_state=None`.
- Evidence for sorted project convention: existing `_build_repr` and `_pprint`
  sort parameter keys, and public in-repository tests assert sorted-order
  strings for other cross-validation splitters.
- Decision: keep V1 using `_build_repr`/`_pprint` sorted order. The issue's
  operative defect is object identity output plus missing `n_splits`; the public
  hint explicitly points to `_build_repr` and `cvargs`.
- Related obligations: O5, C6.
- Classification: no V2 code change.

F4. Compatibility check: direct attributes must not be overridden by `cvargs`.

- Concrete input: an object with direct attribute `x=None` and `cvargs["x"] = 7`.
- Expected: repr uses `x=None`, preserving direct-attribute behavior.
- V1 status: the sentinel fallback only consults `cvargs` when the direct
  attribute is absent, so direct `None` remains authoritative.
- Related obligations: O3, O8, C4.
- Classification: no open bug.

## Proof-derived findings from `/verify`

P-F1. The constructed proof has no loop, recursion, arithmetic, or termination
obligation. The only proof side condition is the lookup-order condition in O3:
direct attribute lookup must be attempted before `cvargs` lookup. V1 satisfies
that condition.

P-F2. The proof is constructed, not machine-checked. Test removal is not
recommended unless the emitted `kompile` and `kprove` commands are later run and
return `#Top`.

