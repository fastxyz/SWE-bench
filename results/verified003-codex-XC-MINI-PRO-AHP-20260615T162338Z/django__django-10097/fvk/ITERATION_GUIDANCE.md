# Iteration Guidance

## Decision

V1 stands unchanged. The FVK audit did not surface a source-level problem that
requires V2 edits.

## Why no production source edit is needed

- Findings F1 and F2 show the V1 regex fixes the reported delimiter-smuggling
  bug family.
- Finding F3 explains why the visible fixture with raw extra colons is SUSPECT
  legacy evidence, not a reason to loosen the regex.
- Findings F4 and F5 show ordinary credentials and percent-encoded delimiters
  remain accepted.
- Finding F6 shows the IDNA fallback path does not reintroduce acceptance of the
  malformed userinfo cases.
- Proof obligations PO1-PO8 are discharged by the source regex, the constructed
  K claims, and compatibility inspection.

## Recommended tests for a future test-writing pass

Do not edit tests in this benchmark task. If tests are later added by a human or
separate test pass, cover:

- `http://foo/bar@example.com` is invalid.
- `http://foo@bar@example.com` is invalid.
- `http://user:pa:ss@example.com` is invalid.
- representative invalid hosts from `invalid_urls.txt` remain invalid when
  `?m=foo@example.com` is appended.
- `http://userid@example.com` and `http://userid:password@example.com` remain
  valid.
- percent-encoded delimiters such as `%40`, `%2f`, and `%3A` remain valid in
  credential data.

## Proof follow-up

Machine-checking remains optional follow-up outside this session:

```sh
kompile fvk/mini-urlvalidator.k --backend haskell
kast --backend haskell fvk/urlvalidator-spec.k
kprove fvk/urlvalidator-spec.k
```

Until those commands return `#Top`, do not remove tests based on the constructed
proof.
