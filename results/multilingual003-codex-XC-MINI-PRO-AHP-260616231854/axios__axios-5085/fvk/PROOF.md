# FVK Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, tests, Python, or project code were run.

## Machine-Check Commands Not Run

These are the commands to run later in an environment with K installed:

```sh
kompile fvk/mini-axios-headers.k --backend haskell
kast --backend haskell fvk/axiosheaders-spec.k
kprove fvk/axiosheaders-spec.k
```

Expected result after machine checking: `#Top` for all claims in `fvk/axiosheaders-spec.k`.

## What Is Proved

For every in-domain `set-cookie` response header represented as an array of cookie strings, `AxiosHeaders` preserves the array through `set()`, response `normalize()`, and `get('set-cookie')` with no parser argument. The result has the same order, cardinality, and string elements.

The proof is partial correctness over the modeled header operations. There is no loop or termination obligation in this code path.

## Constructed Proof Sketch

1. `parseHeaders()` and Node's `res.headers` can provide an array-valued `set-cookie` header. This is the intended representation per E-001 through E-004.

2. `AxiosHeaders.set()` already branches on arrays and stores `_value.map(normalizeValue)`. By O-002, each cookie string element remains the same string. Therefore `set()` stores an array for `set-cookie`.

3. V1 changed source and non-minified runtime copies so `normalizeValue(array)` returns `array.map(normalizeValue)`. V2 extends that same change to the minified runtime mirrors. By O-001, array shape, order, and cardinality are preserved.

4. `AxiosHeaders.normalize()` writes normalized header values only through `normalizeValue(value)`. By O-003, both assignment paths preserve arrays. This removes the pre-fix `String(array)` behavior that produced the reported comma-joined string.

5. `AxiosHeaders.get(header)` with no parser returns the stored value unchanged. By O-004, after `set()` and `normalize()`, that stored value is the ordered cookie array.

6. Runtime mirror consistency is discharged by O-005. V1 missed `dist/axios.min.js` and `dist/esm/axios.min.js`; V2 patches them.

## Adequacy

The formal claim C-001 says: `normalizeGet("set-cookie", [C1, C2])` returns `[C1, C2]`. This matches the public issue's expected behavior exactly: `AxiosHeaders.get('set-cookie')` should return an array of cookies.

The formal model keeps the property axis that matters: array versus string, order, cardinality, and cookie string elements. It therefore distinguishes the failing pre-fix result from the intended result.

## Residual Risk

The proof is constructed but not machine-checked.

The model is a mini semantics for the property-relevant header operations, not full JavaScript semantics. It relies on the standard behavior that JavaScript `Array.map` preserves order and cardinality.

Source maps were not regenerated. This is a release-process artifact risk, not a runtime behavior risk for this issue.

## Test Guidance

Do not delete tests based on this constructed proof. If machine-checked later, tests that assert `AxiosHeaders.from({ 'set-cookie': ['a', 'b'] }).normalize().get('set-cookie')` returns `['a', 'b']` would be subsumed by O-004. Integration tests for Node response handling should still be kept unless the full adapter path is formally modeled.
