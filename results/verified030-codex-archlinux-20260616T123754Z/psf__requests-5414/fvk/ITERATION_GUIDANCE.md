# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Source Decision

Keep the V1 predicate:

```python
host.startswith(u'*') or host.startswith(u'.') or u'..' in host
```

FVK obligations PO-1 through PO-4 justify this predicate for the reported
failure and the issue-derived empty-label family. PO-6 and PO-7 justify not
broadening the branch to full ASCII IDNA validation.

## V2 Change

Only the adjacent comment needed revision. It now says the ASCII branch rejects
`leading/interior empty labels`, matching the actual guard and PO-7's
trailing-dot compatibility obligation.

## Recommended Tests For A Future Test-Enabled Session

Do not edit tests in this benchmark task. In a normal development session, add
or keep coverage for:

- `requests.Request("GET", "http://.example.com").prepare()` raises
  `InvalidURL` with `URL has an invalid label.`;
- `http://example..com` raises the same `InvalidURL`;
- `http://example.com.` is not rejected by this new ASCII empty-label guard;
- existing wildcard invalid-host behavior still raises `InvalidURL`;
- non-ASCII IDNA behavior remains unchanged.

## Deferred Work

The FVK proof does not establish the full correctness of URL parsing or all DNS
validity rules. A broader hostname-validation policy, such as enforcing maximum
ASCII label length in Requests itself, would need separate public intent or a
separate compatibility decision. Do not fold that broader policy into this
issue fix without new evidence.

## Machine-Check Follow-Up

When a K execution environment exists, run:

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/requests-url-spec.k
kprove fvk/requests-url-spec.k
```

Until those commands return successfully, the proof remains constructed, not
machine-checked.
