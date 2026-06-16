# FVK Proof

Status: constructed, not machine-checked.

## Claim Summary

The proof target is the ASCII-host validation branch of
`PreparedRequest.prepare_url` in `repo/requests/models.py`.

For every ASCII host `H`:

- if `H` starts with `*`, starts with `.`, or contains `..`, the branch reaches
  `InvalidURL('URL has an invalid label.')`;
- otherwise, the new guard does not reject `H`, and the existing Requests URL
  preparation path continues.

The concrete issue input `.example.com` is a member of the second bullet's
invalid-label class because it starts with `.`.

## Proof Sketch

1. URL parsing has already produced a non-empty `host`; otherwise the existing
   `if not host` branch raises `InvalidURL("No host supplied")`, which is not
   the issue path.
2. For the issue input, `unicode_is_ascii(".example.com")` is true, so execution
   enters the ASCII `elif` branch rather than the non-ASCII IDNA branch.
3. The V2 predicate is:
   `host.startswith(u'*') or host.startswith(u'.') or u'..' in host`.
4. For `.example.com`, `host.startswith(u'.')` is true.
5. Therefore the branch raises `InvalidURL('URL has an invalid label.')`.
6. Because the exception is raised before network-location reconstruction and
   request sending, the lower layer that produced raw `UnicodeError` is
   unreachable on this path.

The same symbolic reasoning covers `example..com`: `u'..' in host` is true, so
the same `InvalidURL` branch fires. The existing wildcard case remains covered
by `host.startswith(u'*')`.

For an ASCII host with none of those predicates true, the new condition is false
and the code falls through to the pre-existing network-location reconstruction.
This discharges the compatibility obligation for valid ASCII hosts within the
scope of this fix.

## Constructed K Proof Shape

The reduced semantics in `fvk/mini-python.k` models the relevant branch as:

```k
rule <k> prepareAsciiHost(H) => invalidURL("URL has an invalid label.") ... </k>
  requires BadAsciiHost(H)

rule <k> prepareAsciiHost(H) => validHost(H) ... </k>
  requires notBool BadAsciiHost(H)
```

The spec in `fvk/requests-url-spec.k` supplies five reachability claims:

- concrete `.example.com` reaches `invalidURL`;
- symbolic `StartsWith(H, ".")` reaches `invalidURL`;
- symbolic `Contains(H, "..")` reaches `invalidURL`;
- symbolic `StartsWith(H, "*")` reaches `invalidURL`;
- symbolic `notBool BadAsciiHost(H)` reaches `validHost(H)`.

Each invalid-host claim rewrites in one step by the first rule after the
`BadAsciiHost` predicate simplifies to true. The valid-host claim rewrites in
one step by the second rule under the negated predicate.

There are no loops or recursion in the modeled branch, so there are no loop
circularities or termination measures to discharge.

## Adequacy Result

The formal claims match the intent-only requirements in `fvk/SPEC.md`:

- the concrete reported host is covered;
- the issue-derived leading/interior empty-label family is covered;
- existing wildcard behavior is preserved;
- non-ASCII IDNA behavior is outside the changed branch and unchanged;
- full ASCII IDNA validation is intentionally not added.

## Residual Risk

This proof is partial and reduced to the branch that caused the issue. It does
not prove all of `PreparedRequest.prepare_url`, all of Requests URL parsing, DNS
resolution, networking, or urllib3 behavior. It also has not been machine
checked.

The exact commands to machine-check later are:

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/requests-url-spec.k
kprove fvk/requests-url-spec.k
```

Expected result after a successful machine check: all claims discharge to
`#Top`.

## Test Guidance

No test files were modified. After machine-checking the K claims, unit tests
that only assert the in-scope host predicate behavior may be considered
redundant with the proof, but integration tests through `requests.get` should be
kept because this proof abstracts away request sending and lower networking
layers.
