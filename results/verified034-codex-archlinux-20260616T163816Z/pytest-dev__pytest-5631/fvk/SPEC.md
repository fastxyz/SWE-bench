# FVK Spec

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## Scope

Audited unit: `repo/src/_pytest/compat.py::num_mock_patch_args`.

Relevant call path: `getfuncargnames` trims leading function arguments by the
number returned from `num_mock_patch_args`; fixture discovery then uses the
remaining argument names. The audited change is the predicate that decides
whether one `mock.patch` patching object consumes a generated mock argument.

There are no loops in the source unit. The proof obligation is structural over
the finite `patchings` sequence.

## Intent Spec

I-001, prompt evidence: "ValueError when collecting tests that patch an array"
and the example `@patch(target='XXXXXX', new=np.array([-5.5, 3.0]))`.
Semantic obligation: collection must not fail merely because an explicit
`new=` object has array-like equality behavior.

I-002, prompt evidence: "`p.new in sentinels` returns an array of booleans
instead of a boolean which causes the ValueError."
Semantic obligation: sentinel detection must not invoke equality or truth-value
conversion on arbitrary explicit `new=` values.

I-003, source comment evidence: `num_mock_patch_args` says it returns the
"number of arguments used up by mock arguments".
Semantic obligation: only patch decorators that create mock arguments should be
counted.

I-004, public test/source evidence: mock integration tests around
`getfuncargnames` expect default patch decorators to consume generated mock
arguments, while explicit `new=...` values such as `new=MagicMock` do not add a
function argument for pytest to remove.
Semantic obligation: `new is mock.DEFAULT` or `new is unittest.mock.DEFAULT`
counts; other explicit `new=` values do not.

I-005, compatibility evidence: no public API or signature change was requested.
Semantic obligation: keep the helper signature, return type, and surrounding
fixture-discovery behavior unchanged except for avoiding unsafe equality.

## Formal English Spec

For a function object `function`:

1. If `function` has no `patchings` attribute or it is empty, return `0`.
2. If neither `mock` nor `unittest.mock` is loaded, preserve the existing
   fallback of returning `len(patchings)`.
3. If at least one mock module is loaded, build the set of loaded module
   `DEFAULT` sentinel object identities.
4. Return the count of patching objects `p` for which both are true:
   `not p.attribute_name`, and `p.new` is identical to one of the loaded
   `DEFAULT` sentinels.
5. During the predicate in item 4, do not call `p.new.__eq__`, do not evaluate
   an equality result as truthy, and do not otherwise depend on the equality
   semantics of explicit `new=` objects.
6. Do not mutate `function`, `patchings`, patching objects, mock modules, or
   sentinel objects.

## Adequacy Audit

The formal spec matches the public intent for the reported bug: I-001 and I-002
require avoiding equality on array-like `new=` values, and item 5 states that
directly.

The formal spec preserves the intended mock argument counting behavior: I-003
and I-004 require default patch decorators to count and explicit replacements
to not count. Items 3 and 4 encode that as identity against `DEFAULT`
sentinels.

Item 2 is a compatibility frame condition for a pre-existing fallback branch.
It is not used to justify the bug fix, but retaining it avoids expanding the
change beyond the prompt. No FVK finding requires changing it.

Item 6 is a frame condition inferred from helper purpose and implementation:
the function computes a count only. V1 satisfies it because the change is a
read-only predicate.

## Public Compatibility Audit

Changed symbol: `_pytest.compat.num_mock_patch_args`.

Compatibility result: pass. The V1 patch keeps the same function name,
signature, return type, callers, imports, and fallback branch. It changes only
the internal sentinel predicate from equality-based membership to identity
membership.

No public test files were modified.

## Formal Core

The supporting K-style artifacts are:

- `fvk/mini-patchcount.k`: a minimal semantics for identity-based counting over
  patch metadata.
- `fvk/num-mock-patch-args-spec.k`: reachability claims for the reported
  array-like explicit `new=`, the default sentinel case, and a mixed patching
  sequence.

Exact commands to run later, not executed here:

```sh
cd fvk
kompile mini-patchcount.k --backend haskell
kast --backend haskell num-mock-patch-args-spec.k
kprove num-mock-patch-args-spec.k
```
