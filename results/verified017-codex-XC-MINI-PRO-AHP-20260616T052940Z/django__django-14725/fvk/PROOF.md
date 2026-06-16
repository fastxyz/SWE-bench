# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

Formal files:

- `fvk/mini-model-formset.k`
- `fvk/model-formset-spec.k`

Future machine-check commands:

```sh
cd fvk
kompile mini-model-formset.k --backend haskell
kast --backend haskell model-formset-spec.k
kprove model-formset-spec.k
```

Expected outcome after a successful future machine check: `kprove` reduces the
claims to `#Top`.

## Claim K-1: edit-only save

Claim: for all `E >= 0` and `N >= 0`, `save(true, E, N)` reaches a state with
`created = 0`, `newObjects = 0`, `result = E`, and `editOnly = true`.

Proof sketch:

1. The initial `<k>` cell matches the first `save(true, E, N)` rule in
   `mini-model-formset.k`.
2. The side condition `E >=Int 0 andBool N >=Int 0` is exactly the claim
   precondition.
3. One rewrite step sets `created` and `newObjects` to `0`, sets `result` to
   `E`, sets `editOnly` to `true`, and consumes the computation.
4. No rule dispatches to `saveNewObjects`; therefore no new-object creation
   event is reachable on this path.

Code correspondence: V2 `BaseModelFormSet.save()` checks `self.edit_only`,
sets `self.new_objects = []`, and returns `self.save_existing_objects(commit)`
before the virtual call to `self.save_new_objects(commit)`.

Discharges: PO-2, PO-3, PO-4, PO-7.

## Claim K-2: normal save

Claim: for all `E >= 0` and `N >= 0`, `save(false, E, N)` reaches a state with
`created = N`, `newObjects = N`, `result = E + N`, and `editOnly = false`.

Proof sketch:

1. The initial `<k>` cell matches the `save(false, E, N)` rule.
2. The non-negative side condition is the claim precondition.
3. One rewrite step records the normal creation count `N` and returns
   `E + N`.

Code correspondence: when `self.edit_only` is false, V2 leaves the original
`save_existing_objects(commit) + save_new_objects(commit)` expression intact.

Discharges: PO-5.

## Claim K-3: direct base `save_new_objects()` in edit-only mode

Claim: for all `N >= 0`, `saveNewObjects(true, N)` reaches `created = 0`,
`newObjects = 0`, `result = 0`, and `editOnly = true`.

Proof sketch:

1. The initial `<k>` cell matches the `saveNewObjects(true, N)` rule.
2. The side condition `N >=Int 0` is the claim precondition.
3. One rewrite step returns the empty creation result.

Code correspondence: the base `BaseModelFormSet.save_new_objects()` method
initializes `self.new_objects = []` and returns immediately when
`self.edit_only` is true.

Discharges: PO-4.

## Claim K-4: normal base `save_new_objects()`

Claim: for all `N >= 0`, `saveNewObjects(false, N)` reaches `created = N`,
`newObjects = N`, `result = N`, and `editOnly = false`.

Proof sketch:

1. The initial `<k>` cell matches the `saveNewObjects(false, N)` rule.
2. The side condition `N >=Int 0` is the claim precondition.
3. One rewrite step records the ordinary eligible-extra-form creation count.

Code correspondence: when `self.edit_only` is false, V2 leaves the original
base loop over changed, non-deleted extra forms intact.

Discharges: PO-5.

## Claim K-5: factory propagation

Claim: for every boolean `B`, `factory(B)` reaches `editOnly = B`.

Proof sketch:

1. The initial `<k>` cell matches the `factory(B)` rule.
2. One rewrite step sets the formset class flag to the caller-provided boolean.

Code correspondence: `modelformset_factory()` assigns
`FormSet.edit_only = edit_only`; the inline and generic inline factories pass
the same keyword through.

Discharges: PO-6 and PO-8.

## Adequacy and Completeness Check

The formal model represents the property axis changed by the issue:
new-object creation. It distinguishes the passing case (`created = 0`) from the
failing case (`created = N`, `N > 0`) under `edit_only=True`, so the abstraction
is not vacuous for this defect.

The proof covers the base `save()` path, the base direct `save_new_objects()`
path, the default non-edit-only frame condition, and factory propagation. It
does not claim to control subclasses that replace `save()` entirely; that
boundary is recorded as Finding F-7.

## Test Guidance

No tests were run and no test files were modified.

Tests to add or keep in a conventional test pass:

- A model formset with `edit_only=True`, tampered management form data, and
  eligible extra-form data creates no new object on `save()`.
- A custom formset subclass overriding `save_new_objects()` cannot create new
  objects through `save()` when `edit_only=True`.
- `formset.new_objects` is `[]` after edit-only `save()`.
- `edit_only=False` continues to create eligible extra-form objects.
- Inline and generic inline factory paths propagate `edit_only=True`.

No test removal is recommended because the proof has not been machine-checked.
