# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`, or `kprove` were executed.

## Claims Proved in This Audit

The constructed proof covers:

- PO-1: plain columns with a non-empty suffix render as `Q S`.
- PO-2: plain columns with an empty suffix render as `Q`.
- PO-3: opclass columns with an empty suffix render as `Q O`.
- PO-4: opclass columns with a non-empty suffix render as `Q O S`.
- PO-5: the existing comma-space delimiter and public call signatures are preserved.

Here `Q` is the quoted column token, `O` is an opclass token, and `S` is a bare non-empty order suffix token such as `DESC`.

## Symbolic Proof Sketch

For `Columns.__str__()`:

1. `col = quote_name(column)` gives the quoted token `Q`.
2. If `idx` is present in `col_suffixes`, `suffix` is that entry; otherwise `suffix = ''`.
3. The returned per-column string is `' '.join(part for part in (Q, suffix) if part)`.
4. Case `suffix == ''`: the filtered sequence is `[Q]`, so the result is `Q`. This discharges PO-2.
5. Case `suffix != ''`: the filtered sequence is `[Q, suffix]`, so the result is `Q + " " + suffix`. This discharges PO-1.

For `IndexColumns.__str__()`:

1. `col = quote_name(column)` gives the quoted token `Q`.
2. Public construction requires `opclasses` to have the same length as `columns`, so `self.opclasses[idx]` exists for each rendered column and gives token `O`.
3. If `idx` is present in `col_suffixes`, `suffix` is that entry; otherwise `suffix = ''`.
4. The returned per-column string is `' '.join(part for part in (Q, O, suffix) if part)`.
5. Case `suffix == ''`: the filtered sequence is `[Q, O]`, so the result is `Q + " " + O`. This discharges PO-3.
6. Case `suffix != ''`: the filtered sequence is `[Q, O, suffix]`, so the result is `Q + " " + O + " " + suffix`. This discharges PO-4.

For both helpers, the outer return statement remains `', '.join(...)`, so multi-column delimiter behavior is preserved. No public signatures or dispatch points changed, discharging PO-5.

## Adequacy Gate

`fvk/FORMAL_SPEC_ENGLISH.md` paraphrases the K claims as the same obligations listed in `fvk/INTENT_SPEC.md`. `fvk/SPEC_AUDIT.md` marks each obligation as pass. The only out-of-domain note is F-4, which concerns pre-spaced suffix fragments not produced by the public call path.

## K Artifacts

The constructed K-style core is:

- `fvk/mini-python.k`
- `fvk/index-columns-spec.k`

Commands to run later:

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/index-columns-spec.k
kprove fvk/index-columns-spec.k
```

Expected machine-check result, if the toolchain accepts the mini semantics and claims: `#Top`.

## Test Recommendations

No test files were modified.

After machine-checking, unit tests that assert the exact four in-domain string shapes above would be subsumed by the proof for those helper contracts. Integration tests that exercise real database schema editors should be kept, because this proof abstracts the surrounding database-specific SQL assembly and does not prove backend execution behavior.

## Residual Risk

The proof is partial and constructed only. It verifies the string-token rendering contract under the sourced domain, not arbitrary user-supplied pre-spaced SQL fragments and not database parser behavior. The trusted base is the adequacy of the mini string-renderer semantics and the later K toolchain result.
