# PROOF

Status: constructed, not machine-checked. No K tooling, tests, Node code, or Python were executed.

## Formal Core

Semantics:

`fvk/mini-js-formdata.k`

Claims:

`fvk/axios-formdata-spec.k`

Intended machine-check commands, not executed:

```sh
kompile fvk/mini-js-formdata.k --backend haskell
kast --backend haskell fvk/axios-formdata-spec.k
kprove fvk/axios-formdata-spec.k
```

Expected machine-check result after command execution in a proper environment:

`#Top`

## Proof Sketch

### Claim 1: Spec-compliant Node `FormData`

Precondition:

`N >= 0`, representing a finite multipart body length.

Symbolic execution:

1. Start from `adapter(SpecFormData(N), headers("multipart/form-data", 0))`.
2. The mini semantics checks the adapter branches in source order.
3. `SpecFormData(N)` is not `LegacyFormData`, so the legacy `getHeaders()` branch does not fire.
4. `SpecFormData(N)` satisfies the spec-compliant branch, so execution rewrites to `formDataToStream(SpecFormData(N), H)`.
5. `formDataToStream` rewrites to `ok(StreamData, headers(multipartContentType, multipartLength(N)))`.
6. Simplification rewrites `multipartContentType` to `multipart/form-data; boundary=<generated>` and `multipartLength(N)` to `N` under `N >= 0`.

Postcondition:

`ok(StreamData, headers("multipart/form-data; boundary=<generated>", N))`

This proves PO1, PO2, and PO3 in the abstract model. PO4 is discharged for finite string/blob sizes by the source-level arithmetic described in `PROOF_OBLIGATIONS.md`.

### Claim 2: Legacy `form-data`

Precondition:

`L >= 0`, representing package-provided length/header information.

Symbolic execution:

1. Start from `adapter(LegacyFormData(L), headers("multipart/form-data", 0))`.
2. The first adapter branch is the legacy `getHeaders()` branch.
3. The semantics rewrites directly to `ok(LegacyFormData(L), headers("legacy-form-data-headers", L))`.
4. The spec-compliant branch is unreachable for this input because source order already selected the legacy branch.

This proves PO6.

### Claim 3: Unsupported object

Symbolic execution:

1. Start from `adapter(OtherObject, headers("", 0))`.
2. The value is neither legacy `FormData`, spec-compliant `FormData`, stream, buffer, nor string.
3. The unsupported-object rule rewrites to the original adapter rejection.

This proves PO7 and shows the fix is not an arbitrary-object broadening.

## Adequacy and Compatibility

`fvk/SPEC_AUDIT.md` passes after V2. `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` identified V1's stale CommonJS bundle as a public compatibility gap; V2 resolved it by mirroring the source fix into `repo/dist/node/axios.cjs`.

## Residual Risk

The proof is partial correctness only and constructed, not machine-checked. It abstracts multipart bytes rather than proving every byte sequence in K. Source inspection covers the byte layout:

- each part begins with `--boundary\r\n`;
- each part receives `Content-Disposition`;
- Blob/File parts receive `filename` and `Content-Type`;
- each part ends with `\r\n`;
- the body ends with `--boundary--\r\n`.

No tests are recommended for removal. Existing and hidden integration tests should remain because network I/O, parser interoperability, and package build consistency are outside the constructed proof.
