# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Claim proved, conditionally on the model

For every in-domain paste content `C`, the request constructed by
`create_new_paste(C)` is:

```text
request("https://bpaste.net", C, "text", "1week")
```

This proves the source-level request metadata obligation for both pytest pastebin
modes, because both modes call `create_new_paste`.

## Symbolic execution sketch

1. Start with symbolic content `C`.
2. Execute the request-parameter construction in `create_new_paste`.
3. The `code` field is assigned `C`.
4. The `lexer` field is assigned the literal `"text"`.
5. The `expiry` field is assigned the literal `"1week"`.
6. The target URL is assigned the literal `"https://bpaste.net"`.
7. The call to `urlopen` receives `urlencode(params).encode("ascii")`; the relevant
   pre-network observable therefore contains `code=C`, `lexer=text`, and
   `expiry=1week`.

There are no loops or recursive calls in this audited slice, so there are no loop
circularities. The proof is a straight-line reachability proof.

## Pre-fix countermodel

If the old implementation is modeled instead, step 4 assigns `lexer=python3` on
Python 3 or `lexer=python` on Python 2. That state is distinguishable from the
postcondition term with `lexer=text`, so the claim fails. This localizes the issue
to the request metadata and shows why V1's literal `text` assignment is the needed
repair.

## Adequacy gate

The formal claim says exactly what the public issue requires: pytest terminal output
is uploaded as plain text. It does not prove a legacy-derived contract because the
only conflicting public test expects the behavior the issue reports as wrong and is
marked SUSPECT in F-002.

## Residual risk

The proof does not model external networking, service availability, bpaste.net
validation unrelated to the lexer field, or malformed response handling. It also
has not been machine-checked. Running the commands in `fvk/PROOF_OBLIGATIONS.md`
is required before treating the K proof as machine verified.

## Test guidance

Do not delete tests based on this constructed proof. In ordinary project
maintenance, the unit assertion that checks the encoded lexer should be updated to
expect `lexer=text`; this benchmark forbids test edits, so no test files were
modified.
