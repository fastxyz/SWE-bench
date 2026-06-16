# Constructed Proof

Status: constructed, not machine-checked. No K tooling was run.

## Claims proved on paper

The formal core is:

- `mini-python.k`: an abstract mini semantics for the relevant autodoc branch
  behavior.
- `autodoc-module-all-spec.k`: reachability claims for absent `__all__`,
  explicit `__all__`, empty explicit `__all__`, filtering of forced-skipped
  members, and the explicit-member-list frame condition.

## Proof sketch

### `NO-ALL-BRANCH`

Initial state:

- `getObjectMembers(true, noAll, MS, SELECTED)`

Semantic step:

- The `noAll` rule rewrites directly to `result(true, MS)`.

Meaning:

- Absent or ignored `__all__` still returns `members_check_module = True` and
  unmodified members, preserving the legacy implicit-member path.

Discharges: PO-5.

### `EXPLICIT-ALL-BRANCH`

Initial state:

- `getObjectMembers(true, exports(NS), MS, SELECTED)`

Semantic step:

- The explicit export rule rewrites directly to
  `result(false, markSkipped(NS, MS))`.

Meaning:

- Any valid explicit export sequence, regardless of length, disables the
  implicit-module check and marks members not present in that sequence as
  forced skipped.

Discharges: PO-1, PO-3.

### `EMPTY-ALL-BRANCH`

Initial state:

- `getObjectMembers(true, exports(.Names), MS, SELECTED)`

Semantic steps:

1. This is an `exports(NS)` case with `NS = .Names`.
2. The explicit export rule rewrites to
   `result(false, markSkipped(.Names, MS))`.
3. Recursive simplification of `markSkipped(.Names, MS)` marks every member
   skipped, because `in(N, .Names)` is always false.

Meaning:

- Empty explicit `__all__` is not absent. It enters the explicit export path,
  and every member becomes forced skipped.

Discharges: PO-1, PO-2, PO-3.

### `EMPTY-ALL-FILTER`

Initial state:

- `filterMembers(markSkipped(.Names, MS))`

Semantic steps:

1. `markSkipped(.Names, .Members)` rewrites to `.Members`.
2. `markSkipped(.Names, member(N, SKIP); MS)` rewrites to
   `member(N, true); markSkipped(.Names, MS)`.
3. `keepUnskipped(member(N, true); REST)` drops the head member.
4. By structural induction over the finite member list, every member is dropped
   and the final result is `.Members`.

Meaning:

- With no user skip-event override, the final default documented member list is
  empty for `__all__ = []`.

Discharges: PO-4 and the issue expectation.

### `EXPLICIT-MEMBERS-FRAME`

Initial state:

- `getObjectMembers(false, AS, MS, SELECTED)`

Semantic step:

- The non-`want_all` rule rewrites directly to `result(false, SELECTED)`.

Meaning:

- The V1 edit does not affect explicit `:members: foo,bar` selection.

Discharges: PO-7.

## Adequacy gate

`FORMAL_SPEC_ENGLISH.md` paraphrases the claims above. `SPEC_AUDIT.md` compares
them against `INTENT_SPEC.md`; all required behaviors pass. The only scoped
limitation is the public `autodoc-skip-member` event extension point, which is
handled as a compatibility/frame condition rather than as part of the default
issue output.

## Test recommendation

No test files were modified. Existing public tests for non-empty `__all__`,
`ignore-module-all`, and skip-event override should be kept. A future regression
test for `__all__ = []` with `:members:` would be directly subsumed by
`EMPTY-ALL-FILTER` after machine-checking, but should still be kept unless and
until the emitted K commands return `#Top`.

## Machine-check commands recorded, not run

```sh
cd fvk
kompile mini-python.k --backend haskell
kast --backend haskell autodoc-module-all-spec.k
kprove autodoc-module-all-spec.k
```

Expected result after a future machine check: `kprove` returns `#Top` for all
claims. This session does not claim that result.
