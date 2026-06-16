# Constructed Proof

Status: constructed, not machine-checked. No K tooling, Python, or tests were
run.

## Claims Proved

The mini semantics in `mini-submit-row.k` reduce:

```text
showSaveAsNew(is_popup, has_add_permission, has_change_permission, change, save_as)
```

to:

```text
not is_popup
and has_add_permission
and has_change_permission
and change
and save_as
```

The claims in `submit-row-spec.k` cover:

* `NO_ADD`: no add permission implies the flag is false.
* `NO_CHANGE`: no change permission implies the flag is false.
* `NO_CHANGE_FORM`: non-change forms do not show the flag.
* `POPUP`: popup forms do not show the flag.
* `SAVE_AS_DISABLED`: `save_as = false` does not show the flag.
* `POSITIVE`: when all required conditions hold, the flag is true.

There are no loops or recursive calls in the modeled expression, so there are no
loop circularities.

## Proof Sketch

The proof is direct symbolic reduction.

1. Start with the symbolic call
   `showSaveAsNew(IP, HA, HC, CH, SA)`.
2. Apply the semantic rewrite rule:
   `showSaveAsNew(IP, HA, HC, CH, SA) => notBool(IP) andBool HA andBool HC andBool CH andBool SA`.
3. For each negative claim, instantiate the relevant symbolic argument to the
   false-making value. Boolean conjunction reduces to false when any conjunct is
   false.
4. For the positive claim, instantiate all conjuncts to true and `IP` to false.
   `notBool(false)` reduces to true, and the conjunction of true values reduces
   to true.
5. The template rendering obligation follows by source inspection: the template
   wraps the `_saveasnew` input in `{% if show_save_as_new %}`.
6. The backend guard obligation follows by source inspection:
   `_changeform_view()` converts `_saveasnew` POSTs into add requests and checks
   `has_add_permission` before saving.

## Adequacy Gate

The formal English in `FORMAL_SPEC_ENGLISH.md` matches the intent-only
obligations in `INTENT_SPEC.md`; see `SPEC_AUDIT.md`. The compatibility audit
does not identify an API, signature, caller, or template-variable mismatch.

## Machine-Check Commands

These commands are recorded for a future environment with K installed. They were
not executed.

```sh
cd fvk
kompile mini-submit-row.k --backend haskell
kast --backend haskell submit-row-spec.k
kprove submit-row-spec.k
```

Expected result after any syntax adjustments required by the installed K version:
all claims discharge to `#Top`.

## Test Recommendation

No test files were read or modified, and no test removal is recommended. If a
maintainer adds explicit tests, the useful cases are F1's no-add-permission case,
F2's no-change-permission case, the all-true positive case, and the backend
forged-POST denial described in F3.
