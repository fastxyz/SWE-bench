# FVK Specification

Status: constructed, not machine-checked.

## Scope

The audited unit is the request construction performed by
`repo/src/_pytest/pastebin.py:create_new_paste`. The surrounding pytest hooks are
included only as producer/callsite evidence showing that both `--pastebin=all` and
`--pastebin=failed` flow through this helper.

The proof is a source-level partial-correctness proof for the request fields before
the network call. It does not prove bpaste.net availability, network behavior, or
malformed response handling.

## Public intent ledger

| ID | Evidence | Obligation |
| --- | --- | --- |
| I-001 | The issue says pytest output is submitted to bpaste.net using `lexer=python3`. | Model the bpaste request body as the relevant observable. |
| I-002 | The issue says some contents raise HTTP 400 with that lexer. | Do not preserve the Python lexer as intended behavior. |
| I-003 | The issue says the call succeeds if `lexer` is changed to `text`. | The lexer field must be exactly `text`. |
| I-004 | The issue says pytest console output is arbitrary text, not Python code. | The rule applies to all pastebin uploads of pytest terminal output. |
| I-005 | The source routes both pastebin modes through `create_new_paste`. | A helper-level fix covers both modes if it is content-independent. |
| I-006 | The public test expects `lexer=python3` or `lexer=python`. | SUSPECT legacy evidence because it conflicts with I-003/I-004. |

## Contract

For every in-domain `contents` value representing pytest terminal output, before
the network call `create_new_paste(contents)` must construct a bpaste request with:

- destination URL `https://bpaste.net`;
- `code` equal to `contents`;
- `lexer` equal to `text`;
- `expiry` equal to `1week`.

The `lexer` value must not depend on Python runtime version. The function signature
and successful response URL format are frame conditions and should remain unchanged.

## Formal core

The K fragment is in `fvk/mini-pastebin.k`, and the reachability claim is in
`fvk/pastebin-spec.k`. The model keeps the exact property under audit visible: a
request with `lexer=text` and a request with `lexer=python3` are distinct terms.

Machine-check commands to run in an environment with K installed:

```sh
cd fvk
kompile mini-pastebin.k --backend haskell
kast --backend haskell pastebin-spec.k
kprove pastebin-spec.k
```

Expected outcome if machine-checked: `#Top` for the single request-construction
claim. These commands were not run.

## Adequacy result

The English meaning of the K claim matches the public issue: upload pytest terminal
output as plain text. The old public unit-test assertion for a Python lexer is not
adequate spec evidence because it preserves the behavior the issue identifies as
wrong.
