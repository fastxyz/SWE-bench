# FVK Notes

## Source decisions

FINDING F1 and PO5 showed that V1 did not cover the public constructor spelling
`Request('GET', url, data=None)`: source reasoning showed it still became an
empty stream and received `Content-Length: 0`. I changed
`repo/requests/models.py` so `Request.__init__` normalizes `data=None` to `{}`
instead of `[]`, making explicit `None` follow the same bodyless path as omitted
data.

FINDING F2 and PO1 confirm that the V1 `prepare_content_length` guard should
stand: `body is None and method == 'GET'` now returns before any automatic
header write. PO6 also justifies keeping that guard for the auth recomputation
path.

FINDING F3 and PO2 justify leaving actual `GET` bodies alone: if `body is not
None`, the guard does not fire and the existing length calculation remains in
effect.

FINDING F4 and PO3 justify preserving non-`GET` bodyless behavior. The public
issue targets `GET`, and the earlier "attach Content-Length" behavior for other
methods is not contradicted by the allowed evidence.

FINDING F5 records two possible broader changes, `HEAD` and explicit empty
iterables, as underspecified. I did not edit those paths because no public
evidence in the allowed inputs requires broadening the fix beyond
default/bodyless `GET` and `data=None` as a no-body spelling.

## Artifacts

The FVK artifacts are in `fvk/`. `PROOF.md` includes exact `kompile`, `kast`,
and `kprove` commands for a later environment with K installed. They were not
executed here, and the proof remains constructed, not machine-checked.
