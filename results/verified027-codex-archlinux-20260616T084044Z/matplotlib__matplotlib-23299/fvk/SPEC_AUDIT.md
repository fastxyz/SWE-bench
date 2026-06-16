# Spec Audit

Constructed, not machine-checked.

| Formal claim | Intent coverage | Result |
| --- | --- | --- |
| Claim 1: loaded backend, stale sentinel preserves `Gcf.figs` | Matches intent items 2 and 3 and evidence E1-E4. It models the reported `rc_context()` path directly. | Pass |
| Claim 2: initial lazy resolution | Matches intent item 4 and evidence E5-E6. It preserves lazy backend selection when no backend is loaded. The empty-`Gcf.figs` precondition is justified because pyplot figure managers require backend loading. | Pass |
| Claim 3: concrete backend read | Matches intent item 1 and the general frame condition that ordinary reads should not close figures. | Pass |

## Adequacy Notes

- The formal model abstracts a backend module to a concrete `Backend` token and
  abstracts `Gcf.figs` to a `Figs` value. This is adequate for the issue because
  the property under test is whether the collection is preserved or cleared.
- The model intentionally keeps `switchBackend` destructive. That matches the
  public `pyplot.switch_backend` contract and prevents the proof from proving
  the wrong fix by weakening real backend-switch behavior.
- No formal claim relies on the buggy pre-fix display as expected behavior. The
  actual `OrderedDict()` after `get_backend()` is treated as SUSPECT legacy
  evidence and rejected by evidence E1-E2.
