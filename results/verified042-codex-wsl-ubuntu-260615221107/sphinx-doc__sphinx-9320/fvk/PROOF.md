# Proof

Status: constructed, not machine-checked. No K tooling, Python, tests, or
project code were executed in this benchmark session.

## Claims proved in the constructed model

- `QS-EXISTING-ROOT`: existing `<root>/conf.py` causes warning, status `1`, no
  replacement prompt, and no generation.
- `QS-EXISTING-SOURCE`: existing `<root>/source/conf.py` causes the same
  outcome.
- `QS-NO-CONF-FRAME`: when neither existing-project marker is present, the
  reduced model does not take the existing-project branch and reaches generation.

## Symbolic proof sketch

### QS-EXISTING-ROOT

Initial state:

- `<k> mainInteractive </k>`
- `<rootConf> true </rootConf>`
- `<status> 0 </status>`
- `<warning> false </warning>`
- `<replacementPrompt> false </replacementPrompt>`
- `<generated> false </generated>`

Step 1, by the `mainInteractive` rule:

`mainInteractive => askUserExisting ~> generate`

Step 2, because `rootConf = true`, by the existing-root rule:

`askUserExisting ~> generate => warnExisting ~> exit(1) ~> generate`

Step 3, by `warnExisting`:

`warning` changes from `false` to `true`.

Step 4, by `exit(I) ~> _REST => .K` with `I = 1`:

`status` changes from `0` to `1`, and the continuation containing `generate` is
discarded. Therefore `generated` remains `false`.

No rule reaches `promptReplacement`, so `replacementPrompt` remains `false`.
This proves the postcondition.

### QS-EXISTING-SOURCE

The proof is the same as QS-EXISTING-ROOT, except Step 2 uses the
`rootConf = false` and `sourceConf = true` rule. The same warning/status/no
prompt/no generation postcondition follows.

### QS-NO-CONF-FRAME

Initial state has `rootConf = false` and `sourceConf = false`.

Step 1:

`mainInteractive => askUserExisting ~> generate`

Step 2, by the non-conflict rule:

`askUserExisting => .K`, leaving `generate` as the next computation.

Step 3, by `generate`:

`generated` changes from `false` to `true`; status remains `0`, warning remains
`false`, and replacement prompt remains `false` in the audited guard model.

This proves the reduced frame claim.

## Adequacy and compatibility

The adequacy gate passes in `fvk/SPEC_AUDIT.md`: the English meaning of the K
claims matches `fvk/INTENT_SPEC.md`. Public compatibility passes in
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md`: no public signature, override, or producer
shape changed.

## Test-redundancy recommendation

No test removal is recommended. The proof is constructed, not machine-checked,
and the task forbids editing tests. Future tests for the existing-project branch
would be regression tests for command integration and should be kept unless the
K claims are machine-checked and mapped to the exact test assertions.

## Machine-check commands

Do not run these in this benchmark session. In a K-enabled environment:

```sh
cd fvk
kompile mini-python-quickstart.k --backend haskell
kast --backend haskell quickstart-spec.k
kprove quickstart-spec.k
```

Expected machine-checked result: `#Top` for all claims.
