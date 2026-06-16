# Constructed Proof

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## Artifacts

Formal core:

- `fvk/mini-mime.k`
- `fvk/fileresponse-content-type-spec.k`

Human-readable audit artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/ITERATION_GUIDANCE.md`

## Claim Summary

The proof covers the content-type selection function modeled from
`FileResponse.set_headers()`:

```text
effectiveContentType(explicit, filename, guess_type_result)
```

The proof obligations are finite case splits over:

1. explicit content type;
2. missing filename;
3. compressed encoding lookup;
4. ordinary guessed content type;
5. fallback to `application/octet-stream`;
6. absence of `Content-Encoding` writes in this branch.

There are no loops or recursion in the modeled code, so no circularity claim is
required.

## Proof Sketch

### PO-2: Brotli Encoding Mapping

Initial symbolic state:

```text
effectiveContentType(noExplicit, file(htmlBr), guess(some(textHtml), br))
```

Symbolic execution:

1. The `noExplicit` and non-empty filename case selects the implicit branch.
2. The guessed encoding is `br`.
3. The compressed encoding map contains `br -> appXBrotli`.
4. The branch returns the mapped compressed-file media type instead of the
   guessed underlying `textHtml`.

Post-state:

```text
appXBrotli
```

This discharges `BR-FILERESPONSE`, corresponding to
`Content-Type: application/x-brotli`.

### PO-3: Unix Compress Encoding Mapping

Initial symbolic state:

```text
effectiveContentType(noExplicit, file(htmlZ), guess(some(textHtml), compress))
```

Symbolic execution:

1. The `noExplicit` and non-empty filename case selects the implicit branch.
2. The guessed encoding is `compress`.
3. The compressed encoding map contains
   `compress -> appXCompress`.
4. The branch returns the mapped compressed-file media type instead of the
   guessed underlying `textHtml`.

Post-state:

```text
appXCompress
```

This discharges `COMPRESS-FILERESPONSE`, corresponding to
`Content-Type: application/x-compress`.

### PO-4: Existing Compressed Mappings

The same lookup proof applies to the pre-existing keys:

```text
gzip  -> appGzip
bzip2 -> appXBzip
xz    -> appXXz
```

The V1 source diff only adds keys and does not mutate these existing mappings,
so the public compressed-file behavior remains stable.

### PO-5: No Content-Encoding

The modeled predicate:

```text
fileResponseSetsContentEncoding(noExplicit, guess(some(textHtml), br))
```

rewrites to:

```text
noContentEncoding
```

This matches the implementation: V1 edits only the `Content-Type` mapping and
does not add a `Content-Encoding` header write in `FileResponse.set_headers()`.

### PO-6: Explicit and Fallback Behavior

For explicit content type:

```text
effectiveContentType(explicit(videoWebm), file(anyFile), guess(some(textHtml), br))
=> videoWebm
```

For missing filename:

```text
effectiveContentType(noExplicit, noFile, noGuess)
=> appOctet
```

For unknown guessed type and no compressed encoding:

```text
effectiveContentType(noExplicit, file(unknownFile), guess(noType, noEncoding))
=> appOctet
```

These branches are unchanged by V1.

## Machine-Check Commands Not Run

The commands a human could run later are:

```sh
cd fvk
kompile mini-mime.k --backend haskell
kast --backend haskell fileresponse-content-type-spec.k
kprove fileresponse-content-type-spec.k
```

Expected result if the constructed claims are accepted by the K toolchain:
`#Top`.

These commands were not executed because the task forbids running K tooling,
tests, Python, or project code.

## Adequacy Result

The English paraphrase of the K claims matches the public intent in `SPEC.md`:

- the reported `.br` and `.Z` examples no longer return `text/html`;
- the existing compressed-file media-type policy is preserved;
- `Content-Encoding` remains absent from `FileResponse`'s implicit compressed
  file handling;
- explicit and fallback behavior remain unchanged.

No proof obligation failed or required a source-code change beyond V1.

## Test Guidance

No test files were modified. Existing public tests for `.gz`, `.bz2`, and `.xz`
remain worth keeping because this proof is constructed but not machine-checked.
Future tests for `.br` and `.Z` would directly exercise PO-2 and PO-3, but the
benchmark instruction forbids editing tests here.
