# Constructed Proof

Status: constructed, not machine-checked. The commands below were not run.

## Claims Proved In The Model

The K claims in `fvk/autodoc-private-members-spec.k` cover:

1. `private-members` option parsing for comma-list, bare, and `True` inputs.
2. Merging explicit private names into absent or finite `members`.
3. Preserving `membersAll` when all members are requested.
4. Keeping selected private members and skipping unselected private members in all-members mode.
5. Preserving all-private bare behavior.
6. Preserving excluded/mock precedence.
7. Preserving explicit-member private-name behavior.
8. Preserving source attribute documentation behavior for selected private attributes.

## Proof Sketch

The proof is a case split over the selector and member-state constructors in `mini-autodoc.k`.

Parsing claims reduce directly by the `parseMembers` rewrite rules:

- `optCsv(NS)` rewrites to `selNames(NS)`.
- `optBare` rewrites to `selAll`.
- `optTrue` rewrites to `selAll`.

Merge claims reduce by constructor cases:

- `mergeMembers(membersAbsent, selNames(NS))` rewrites to `membersList(NS)`.
- `mergeMembers(membersList(MS), selNames(NS))` rewrites to `membersList(appendMissing(MS, NS))`; `appendMissing` recursively skips already-present names and appends missing names.
- `mergeMembers(membersAll, selNames(NS))` rewrites to `membersAll`, preserving all-member gathering while leaving finite private selection for filtering.

Filter claims reduce by the precedence order encoded in `keepPrivate`:

- If `IsExcluded` is true, the result is false.
- Else if `IsMocked` is true, the result is false.
- Else, in all-members mode with a source-documented private attribute, the result is `selected(SEL, Name)`.
- Else, in all-members mode with a documented private member, the result is `selected(SEL, Name)`.
- Else, in all-members mode with an undocumented non-attribute private member, the result is false.
- Else, in explicit-members mode, documented private members and source-documented private attributes remain true under existing rules.

The selected/unselected claims close by `selected(selNames(NS), Name) => contains(NS, Name)` and the finite-list `contains` equations. The all-private claim closes by `selected(selAll, Name) => true`.

## Composition With Source Code

The source code realizes the model as follows:

- `ModuleDocumenter.option_spec` and `ClassDocumenter.option_spec` register `private-members` with `members_option`, matching `parseMembers`.
- `merge_private_members_option()` delegates to `merge_members_option()`, matching `mergeMembers`.
- `filter_members()` calls `has_member_name(self.options.private_members, membername)` in the private all-members branches, matching `selected`.
- The existing branch order for mocked objects and `exclude-members` remains before private filtering.
- The explicit-members path remains `want_all == False`, so explicit private names retain existing behavior.

## Reproduce The Machine Check

These commands are emitted for later verification and were not executed in this task:

```sh
kompile fvk/mini-autodoc.k --backend haskell
kast --backend haskell fvk/autodoc-private-members-spec.k
kprove fvk/autodoc-private-members-spec.k
```

Expected machine-check result after a successful run: `#Top`.

## Test Recommendation

Do not delete tests. Because the proof is constructed but not machine-checked, any redundancy recommendation is conditional. Tests worth adding or keeping are:

- `:members:` plus `:private-members: _one` includes `_one` and excludes `_two`.
- bare `:private-members:` still includes all eligible private members.
- `autodoc_default_options = {'members': True, 'private-members': '_one'}` uses the finite selector.
- `exclude-members` still overrides selected private names.

## Residual Risk

This is a partial-correctness proof over a mini semantics, not a real Python/K execution. It depends on the adequacy of the model mapping in `SPEC_AUDIT.md` and on later `kprove` execution for machine-checked confidence.
