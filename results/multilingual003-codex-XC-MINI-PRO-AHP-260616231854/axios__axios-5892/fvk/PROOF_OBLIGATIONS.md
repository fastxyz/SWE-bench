# FVK Proof Obligations

Status: constructed, not machine-checked.

## O1 - Normalization Adequacy

The JavaScript expression `String(E || '').trim().toLowerCase()` implements the abstract `norm(E)` used in the K specification for all in-scope `content-encoding` header values.

Discharges: F1, F2.

## O2 - Supported Gzip/Compress Dispatch

For non-`HEAD`, non-`204` responses with `decompress !== false`, if `norm(E)` is one of `gzip`, `x-gzip`, `compress`, or `x-compress`, the adapter adds exactly the existing unzip decoder and deletes `content-encoding`.

Discharges: F1.

## O3 - Decompress-False and Absent-Header Frame

If `config.decompress === false`, or if `content-encoding` is absent, the decompression block does not add a decoder and does not delete the header because of this fix.

Discharges: F3.

## O4 - No-Content Frame

If the method is `HEAD` or the response status is `204`, the adapter deletes `content-encoding` and adds no decoder, even when the removed value would normalize to a supported encoding.

Discharges: F3.

## O5 - Header Deletion After Decode

Every successful decode branch that adds a decoder also deletes `content-encoding` before the response headers are wrapped in `AxiosHeaders`.

Discharges: F1, F3.

## O6 - CommonJS Mirror

The packaged Node CommonJS build `repo/dist/node/axios.cjs` contains the same normalization expression as `repo/lib/adapters/http.js`.

Discharges: F2 and public compatibility audit C2.

## O7 - Unsupported Encoding Frame

For any normalized encoding outside the supported set, the switch adds no decoder and leaves the header present, preserving existing behavior.

Discharges: F3.

## O8 - Stacked Encoding Boundary

The proof does not claim support for comma-separated stacked encodings. Any future support would require a new spec over an ordered decoder list.

Discharges: F4 by explicitly marking it out of this proof's domain.

## O9 - Honesty Gate

The proof is constructed only. The commands in `fvk/PROOF.md` must be run with K tooling before claiming machine-checked proof or removing any tests.

Discharges: F5.
