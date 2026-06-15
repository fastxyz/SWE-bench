# PROOF

Status: constructed, not machine-checked.

## Claims

The formal claims are in `fvk/checkbox-splitarray-spec.k`:

- `CHECKBOX-CONTEXT-NO-MUTATE`
- `SPLIT-ARRAY-CHECKED-INDEPENDENT`
- `REPRODUCTION-FALSE-TRUE-FALSE`

The semantics are in `fvk/mini-django-widgets.k`.

## Proof Sketch

### CheckboxInput no-mutation claim

Start with attrs represented by `attrs(C)` and output accumulator `OS`.

The V1 source branch for a checked value is:

```python
if self.check_test(value):
    if attrs is None:
        attrs = {}
    else:
        attrs = attrs.copy()
    attrs['checked'] = True
```

For non-`None` attrs, the generated assignment is applied to the copy, not to the caller-owned attrs object. For `None`, no caller-owned attrs object exists. Therefore the caller attrs state is unchanged after the checkbox render.

The returned context attrs contain `checked` exactly when the original attrs already contained it (`C`) or the value's check predicate is true (`shouldCheck(V)`). This is the K rule:

```k
rule checkedOut(V, attrs(C)) => C orBool shouldCheck(V)
```

The `CHECKBOX-CONTEXT-NO-MUTATE` claim follows by one semantic step for `checkbox(V)`: the `<attrs>` cell rewrites from `attrs(C)` to `attrs(C)`, while `<out>` appends `C orBool shouldCheck(V)`.

### Split-array independence claim

The split-array render loop is modeled as:

```k
rule <k> render(.Values) => .K </k>
rule <k> render(cons(V, VS)) => checkbox(V) ~> render(VS) </k>
```

Proof is by guarded circularity over the value list.

The claim is generalized over an output accumulator `OS`, so the post-state output is `append(OS, expected(VS, C))`.

Base case: `VS = .Values`. Rendering terminates immediately, attrs remain `attrs(C)`, and the output is `append(OS, expected(.Values, C)) = append(OS, .Checks) = OS`.

Step case: `VS = cons(V, Tail)`. The render rule performs one real step to `checkbox(V) ~> render(Tail)`, satisfying guardedness. The checkbox claim appends `C orBool shouldCheck(V)` and leaves attrs as `attrs(C)`. The circularity hypothesis applies to `render(Tail)` with the same unchanged attrs and the shifted accumulator `snoc(OS, C orBool shouldCheck(V))`. The append/snoc definitions yield:

```k
append(snoc(OS, C orBool shouldCheck(V)), expected(Tail, C)) =
  append(OS, expected(cons(V, Tail), C))
```

This uses the explicit simplification lemma in `checkbox-splitarray-spec.k`:

```k
append(snoc(OS, B), CS) => append(OS, ccons(B, CS))
```

Thus every index is computed from the original explicit checked bit and that index's own value, not from earlier values.

### Concrete reproduction

For `C = false` and values `cons(false, cons(true, cons(false, .Values)))`:

- first value: `false orBool shouldCheck(false) = false`
- second value: `false orBool shouldCheck(true) = true`
- third value: `false orBool shouldCheck(false) = false`

The output is `ccons(false, ccons(true, ccons(false, .Checks)))`, matching `[False, True, False]`.

The pre-V1 source would violate the step case after a true value because `attrs['checked'] = True` would update the shared attrs state from `attrs(false)` to `attrs(true)`, making the tail proof compute later false values as checked.

## Machine-Check Commands

Do not run these in this task. They are the commands a developer would run later:

```sh
cd fvk
kompile mini-django-widgets.k --backend haskell
kast --backend haskell checkbox-splitarray-spec.k
kprove checkbox-splitarray-spec.k
```

Expected machine-check result after a working K environment is available: `#Top` for the claims.

## Test Recommendation

No tests were edited. If tests could be added, the useful public regression tests would cover:

- `SplitArrayWidget(forms.CheckboxInput(), size=3)` with `[False, True, False]`;
- the same case with an `id` attr, to show id suffixing is unaffected;
- direct `CheckboxInput.get_context()` with a shared attrs dict to assert the caller dict is unchanged.

No test removal is recommended unless the K claims are actually machine-checked.
