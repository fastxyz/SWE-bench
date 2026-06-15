# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent and source inspection only; no tests or code were run.

## F1: V1 fixes the reported missing `value` param in core validators

Evidence: E1, E2, E4, E5; obligations PO1-PO8.

Before V1, invalid paths in `RegexValidator`, `URLValidator`,
`EmailValidator`, IP validators, `DecimalValidator`, `FileExtensionValidator`,
and `ProhibitNullCharactersValidator` raised `ValidationError` without
`params['value']` on at least one failure path.

Concrete example:

`EmailValidator(message='Email "%(value)s" is not valid.')('blah')`

- Observed before V1 by source inspection: the invalid path raised
  `ValidationError(self.message, code=self.code)` with no params, so
  interpolation of `%(value)s` had no source.
- Expected from public intent: the error params contain `{'value': 'blah'}`.
- V1/V2 source state: `EmailValidator.__call__()` creates
  `params = {'value': value}` and passes it to every direct invalid raise.

Classification: fixed code bug.

## F2: V1 correctly preserves original values through derived-value validators

Evidence: E1, E3, E8; obligations PO3, PO4, PO5.

Several validators inspect derived values: URL punycoded netlocs, email domain
parts, IPv6 literal fragments, file extensions, decimal digit counts, and
HStore key sets. The prompt says "provided value", so the expected param is
the original submitted top-level input.

V1/V2 keeps that behavior. The most important case is `URLValidator`, where a
failed punycode retry is caught and re-raised with the original URL's params,
not the punycoded retry URL.

Classification: confirmed fix property.

## F3: V1 covers the public postgres reusable validator gap

Evidence: E6; obligation PO9.

`django.contrib.postgres.validators.KeysValidator` is documented as a reusable
validator and has direct `ValidationError` raises. V1 adds `value` while
preserving `keys`.

Concrete example:

`KeysValidator(['a'], messages={'missing_keys': 'bad %(value)s %(keys)s'})({})`

- Observed before V1 by source inspection: params contained only `keys`.
- Expected from E1/E6: params contain both `keys` and original value `{}`.
- V1/V2 source state: both missing-key and extra-key errors pass
  `{'keys': ..., 'value': value}`.

Classification: fixed code bug.

## F4: No source change is justified for password validators

Evidence: E1-E5; obligations PO10.

`django.contrib.auth.password_validation` contains public validator classes,
but exposing the raw password through `params['value']` is security-sensitive
and not supported by the public issue's examples or docs. The issue points to
the general validator docs and examples such as email/spreadsheet values, not
password disclosure.

Classification: scope/security boundary; keep V1 unchanged.

UltimatePowers-style question if product scope must expand later:

Should password validators deliberately expose the raw password to custom
messages via `%(value)s`, or should they remain excluded for security?

## F5: No test-removal recommendation

Evidence: verify honesty gate; obligations PO11.

The proof is constructed, not machine-checked, and this task forbids running
tests or K tooling. Existing tests should be kept. Useful future tests would
assert that representative invalid validators expose `error.params['value']`
while preserving existing specialized params.

Classification: test guidance, no code change.
