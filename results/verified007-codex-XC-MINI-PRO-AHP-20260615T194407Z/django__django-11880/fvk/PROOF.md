# Constructed Proof

Constructed, not machine-checked. The task forbids running tests, Python, or K
tooling.

## Claim proved

`FIELD-DEEPCOPY-COPY-ERRORS`: for an allocated `FieldObj` whose widget,
`error_messages`, and validators references are allocated and distinct, executing
`deepcopyField(F)` returns a new field id. The new field points to fresh copied
widget, `error_messages`, and validators ids. The copied `error_messages` object
preserves the source payload and has a different identity from the source
`error_messages` object.

## Symbolic execution sketch

Initial state:

- `<k>` contains `deepcopyField(F)`.
- `<heap>` contains `F |-> FieldObj(WO, EO, VO)` plus objects for `WO`, `EO`,
  and `VO`.
- `<next>` contains fresh id `N`.

The `deepcopyField` rule in `mini-field-copy.k` matches the source field and
its referenced objects in the heap. One rewrite step:

- rewrites `<k>` from `deepcopyField(F)` to result id `N`,
- extends the heap with `N |-> FieldObj(N + 1, N + 2, N + 3)`,
- extends the heap with `N + 1 |-> WidgetObj(WP)`,
- extends the heap with `N + 2 |-> ErrorMessagesObj(EP)`,
- extends the heap with `N + 3 |-> ValidatorsObj(VP)`,
- advances `<next>` to `N + 4`.

The source heap entries are framed through unchanged.

The claim precondition states that `F`, `WO`, `EO`, and `VO` are allocated before
`N`, and are distinct. By integer arithmetic, `N + 2` cannot equal `EO`.
Therefore the copied field's `error_messages` reference is fresh while its
payload is preserved.

There are no loops, so no circularity is needed. The proof is a direct
reachability proof by one semantic rewrite plus consequence on the freshness
side condition.

## Mapping to source code

The semantic rule corresponds to the patched method body:

- `copy.copy(self)` creates the fresh field object.
- `memo[id(self)] = result` records the source-to-copy relation for recursive
  deepcopy behavior.
- `copy.deepcopy(self.widget, memo)` creates an isolated widget copy.
- `copy.deepcopy(self.error_messages, memo)` creates an isolated
  `error_messages` copy.
- `self.validators[:]` creates a new validators list while preserving validator
  object identities.

The added V1 line is exactly the source-level discharge of PO-1 and PO-2.

## Adequacy

The formal English paraphrase in `fvk/FORMAL_SPEC_ENGLISH.md` matches the
intent-only obligations in `fvk/INTENT_SPEC.md`. `fvk/SPEC_AUDIT.md` marks every
required behavior as pass. `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` found no unhandled
callsite or override.

## Test recommendation

Do not remove tests unless the K commands below are run later and `kprove`
returns `#Top`. Useful tests to keep or add would assert direct field
`error_messages` identity isolation, nested mutable message isolation, form
instance isolation, and subclass coverage such as `ChoiceField`.

## Commands not executed

```sh
kompile fvk/mini-field-copy.k --backend haskell
kast --backend haskell fvk/field-deepcopy-spec.k
kprove fvk/field-deepcopy-spec.k
```

Expected result after machine-checking: `kprove` discharges the single claim to
`#Top`.
