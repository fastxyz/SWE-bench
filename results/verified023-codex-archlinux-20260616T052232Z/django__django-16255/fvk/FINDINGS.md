# Findings

Status: FVK audit findings from formalization and constructed verification.

## F-001: Empty Callable `lastmod` Raised `ValueError` Before V1

- Classification: code bug, fixed by V1.
- Input: a `Sitemap` where `items()` returns `[]` and `lastmod` is callable.
- Pre-fix observed behavior: `max([])` raised `ValueError: max() arg is an empty sequence`.
- Expected behavior: return `None`, meaning no latest last modification value is available.
- Evidence: E1, E2, E3.
- Proof obligations: PO-4.
- V1 disposition: discharged by `max([self.lastmod(item) for item in self.items()], default=None)`.
- Source decision: keep V1 unchanged.

## F-002: Catching `ValueError` Would Be Broader Than the Public Hint Requires

- Classification: rejected alternative.
- Input: a user-provided callable `lastmod(item)` that raises `ValueError` for its own domain reason.
- Alternative observed behavior if `except ValueError` were added: the user error would be swallowed and converted to `None`.
- Expected behavior from the public hint: use `max(default=None)` to handle the empty iterable case without changing unrelated `ValueError` propagation.
- Evidence: E3 and E8.
- Proof obligations: PO-4, PO-6.
- V1 disposition: V1 avoids broad exception masking by keeping `except TypeError` unchanged.
- Source decision: keep V1 unchanged.

## F-003: Non-Empty Comparable Callable Behavior Must Stay the Documented Maximum

- Classification: frame condition confirmed.
- Input: callable `lastmod` over items producing comparable date/time values.
- Expected behavior: return the latest value over all items.
- Evidence: E4.
- Proof obligations: PO-5.
- V1 disposition: adding `default=None` to `max()` does not change non-empty comparable results.
- Source decision: keep V1 unchanged.

## F-004: Public Compatibility Remains Intact

- Classification: compatibility finding, no code change required.
- Input: existing caller `views.index()` and subclasses overriding `get_latest_lastmod()`, `items()`, or `lastmod(item)`.
- Expected behavior: no new arguments, no signature change, and unchanged return consumer semantics.
- Evidence: E6, E7, public source call sites.
- Proof obligations: PO-7.
- V1 disposition: source diff is internal to the callable branch expression only.
- Source decision: keep V1 unchanged.

## F-005: Constructed Proof Not Machine-Checked

- Classification: proof honesty / residual risk, not a source bug.
- Input: the emitted K artifacts and claims.
- Observed limitation: no `kompile`, `kast`, or `kprove` command was run.
- Expected process: commands are recorded for later machine checking; tests are not removed.
- Evidence: FVK instructions and user restriction.
- Proof obligations: PO-8.
- Source decision: no source change; keep tests untouched.
