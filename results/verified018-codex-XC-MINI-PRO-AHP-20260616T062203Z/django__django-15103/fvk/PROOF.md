# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`, or `kprove` were run.

## Formal Artifacts

- Mini semantics: `fvk/mini-python-json-script.k`
- K claims: `fvk/json-script-spec.k`

Exact commands to machine-check later, not executed here:

```sh
kompile fvk/mini-python-json-script.k --backend haskell
kast --backend haskell fvk/json-script-spec.k
kprove fvk/json-script-spec.k
```

Expected machine-check result after a valid K setup: `#Top` for all claims.

## Proof Summary

The proof is a straight-line symbolic execution proof over a mini-Python fragment that models only the audited observable: `json_script` output shape and the template filter's delegation.

There are no loops or recursion in the audited code, so no circularity claim is required.

## Utility No-ID Claim

Claim: `jsonScript(V, omitted)` reaches:

```html
<script type="application/json">JSONESC(V)</script>
```

Symbolic execution:

1. Start in a configuration whose `<k>` cell is `jsonScript(V, omitted)`.
2. Apply the no-ID semantic rule from `mini-python-json-script.k`.
3. The result is the no-ID wrapper with unchanged `JSONESC(V)`.

This discharges `PO-1`, `PO-2`, and `PO-4` for omission.

## Utility None Claim

Claim: `jsonScript(V, noneId)` reaches the same no-ID wrapper.

Symbolic execution:

1. Start in a configuration whose `<k>` cell is `jsonScript(V, noneId)`.
2. Apply the `noneId` semantic rule.
3. The result is the no-ID wrapper with unchanged `JSONESC(V)`.

This discharges the `None` part of `PO-2` and `PO-4`.

## Utility ID-Present Claim

Claim: `jsonScript(V, id(E))` reaches:

```html
<script id="HTMLESC(E)" type="application/json">JSONESC(V)</script>
```

Symbolic execution:

1. Start in a configuration whose `<k>` cell is `jsonScript(V, id(E))`.
2. Apply the ID-present semantic rule.
3. The result is the ID-bearing wrapper, with `HTMLESC(E)` in the attribute position and `JSONESC(V)` in the script body.

This discharges `PO-3`, `PO-4`, and the compatibility finding `F-02`.

## Template Filter Delegation Claim

Claim: `filterJsonScript(V, I)` reaches `jsonScript(V, I)`.

Symbolic execution:

1. Start in a configuration whose `<k>` cell is `filterJsonScript(V, I)`.
2. Apply the delegation semantic rule.
3. The result is the corresponding utility call with the same value and ID argument.
4. Compose by transitivity with one of the utility claims above.

This discharges `PO-5` and `PO-6`.

## Template Argument Validation Reasoning

Django's template parser is not modeled as a full K grammar here. The relevant static check is small and source-inspected:

- `FilterExpression.args_check()` sets `plen = len(provided) + 1` to include the implicit filter input.
- It unwraps the filter function and computes `alen = len(args)` and `dlen = len(defaults or [])`.
- It accepts the call when `plen >= alen - dlen` and `plen <= alen`.
- For `def json_script(value, element_id=None)`, `alen == 2` and `dlen == 1`, so `{{ value|json_script }}` has `plen == 1` and is accepted.
- `{{ value|json_script:"test_id" }}` has `plen == 2` and remains accepted.

This source-level proof discharges `PO-5`.

## Adequacy and Completeness Check

The claims cover the full intended runtime behavior space from the issue:

- omitted argument, no ID attribute;
- explicit `None`, no ID attribute by Python optional-argument convention;
- provided ID, existing ID-bearing behavior preserved;
- template filter delegation and argument validation.

The explicit empty-string ID case is not claimed as intent-derived. It is recorded as `F-03`, outside the positive proof obligation, and V1 keeps the compatibility-preserving behavior.

## Residual Risk

This proof abstracts Django's full JSON serialization and HTML escaping as `JSONESC` and `HTMLESC`. That is adequate for this issue because V1 does not change those algorithms; it only changes whether the surrounding `id` attribute is emitted.

Termination is not separately proved. The audited code is straight-line except for library calls to JSON serialization and formatting; the spec is partial correctness over inputs where those calls return.

The proof is constructed, not machine-checked. Test removal is not recommended unless the emitted K commands are run later and `kprove` returns `#Top`.
