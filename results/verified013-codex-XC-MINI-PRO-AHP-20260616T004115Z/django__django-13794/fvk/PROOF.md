# Constructed Proof

Status: constructed, not machine-checked.

## Target

Prove the partial-correctness contract for
`django.template.defaultfilters.add(value, arg)`:

1. resolve Django text promises;
2. try integer addition;
3. otherwise try native Python addition;
4. otherwise return `""`.

There are no loops or recursive calls, so there are no circularity claims.

## Claims

The formal claims are in `add-filter-spec.k`:

- `ADD-INT`: integer addition after text-promise resolution.
- `ADD-PLUS`: native addition after integer coercion fails.
- `ADD-EMPTY`: empty-string fallback after both attempts fail.
- `ADD-LAZY-RIGHT-PLUS`: reported right-lazy string concatenation case.
- `ADD-LAZY-LEFT-PLUS`: symmetric left-lazy string concatenation case.
- `ADD-LAZY-RIGHT-INT`: numeric lazy text remains integer-summed.

## Symbolic Proof Sketch

Start with `<k> add(V, A) </k>`.

1. Apply the `add` rule in `mini-django-template.k`, rewriting to
   `addResolved(resolveText(V), resolveText(A))`.
2. By PO-2, `resolveText(lazyText(S)) = S` and `resolveText(X) = X` for
   non-text-lazy values. This models source lines `defaultfilters.py:678-681`.
3. Case split on `intable(resolveText(V)) and intable(resolveText(A))`.
   - True branch: apply the integer rule and reach
     `toInt(resolveText(V)) +Int toInt(resolveText(A))`, proving `ADD-INT`.
   - False branch: continue to native addition.
4. In the false branch, case split on
   `plusable(resolveText(V), resolveText(A))`.
   - True branch: apply the native-addition rule and reach
     `plusResult(resolveText(V), resolveText(A))`, proving `ADD-PLUS`.
   - False branch: apply the fallback rule and reach `""`, proving
     `ADD-EMPTY`.

For the reported issue, instantiate `V = S:String` and
`A = lazyText(T:String)`. Step 2 rewrites the second operand to `T`, so the
native-addition branch receives `S` and `T`, not `S` and a proxy. Therefore the
proof reaches `plusResult(S, T)` instead of the empty-string fallback whenever
string addition is in-domain. This proves `ADD-LAZY-RIGHT-PLUS` and discharges
F-001.

For numeric lazy text, instantiate `V = S:String` and `A = lazyText(T:String)`
under `intable(S) and intable(T)`. The integer branch fires before native
addition, proving `ADD-LAZY-RIGHT-INT` and discharging F-002.

## Adequacy

`SPEC_AUDIT.md` marks all formal claims as passing against `INTENT_SPEC.md`.
No claim depends only on V1 behavior. The compatibility audit has no unhandled
public API or callsite issue.

## Residual Risk

- The proof is constructed but not machine-checked.
- The K semantics is a deliberate mini-fragment, not full Python semantics.
- Termination is trivial for this straight-line function body and no total
  correctness proof was separately requested.
- Existing and hidden tests are not run in this task.

## Reproduce the Machine Check Later

Do not run these commands in this benchmark environment. They are recorded for
a future environment with K installed:

```sh
kompile fvk/mini-django-template.k --backend haskell
kast --backend haskell fvk/add-filter-spec.k
kprove fvk/add-filter-spec.k
```

Expected machine-check result after any K syntax adjustments required by the
local toolchain: `#Top`.

## Test Guidance

Do not delete tests based on this constructed proof. If machine-checking later
returns `#Top`, direct tests for the proven lazy-text cases are logically
subsumed by the claims, but retaining them is still useful as regression and
integration coverage for Django's real template runtime.

