# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent and static reasoning only.

## F-001: Legacy Default Polluted The User Home Directory

- Classification: code bug fixed by V1 and retained in V2.
- Related obligations: PO-2, PO-3.
- Input: `PYLINTHOME` absent, `HOME=/home/alice`, `XDG_CACHE_HOME` absent.
- Pre-fix observed behavior: `PYLINT_HOME=/home/alice/.pylint.d`.
- Expected behavior: `PYLINT_HOME=/home/alice/.cache/pylint`, because persistent `.stats` files are regenerable cache-like data and should not be stored directly under `$HOME`.
- V2 status: satisfied by `_get_default_pylint_home()`.

## F-002: Absolute `XDG_CACHE_HOME` Must Be Honored

- Classification: required XDG behavior fixed by V1 and retained in V2.
- Related obligations: PO-2.
- Input: `PYLINTHOME` absent, `HOME=/home/alice`, `XDG_CACHE_HOME=/tmp/xdg-cache`.
- Pre-fix observed behavior: `PYLINT_HOME=/home/alice/.pylint.d`.
- Expected behavior: `PYLINT_HOME=/tmp/xdg-cache/pylint`.
- V2 status: satisfied by `_get_default_pylint_home()`.

## F-003: Nested XDG Cache Paths Require Recursive Directory Creation

- Classification: code bug fixed by V1 and retained in V2.
- Related obligations: PO-5.
- Input: selected `PYLINT_HOME=/home/alice/.cache/pylint`, and neither `.cache` nor `.cache/pylint` exists.
- Pre-fix observed behavior: `os.mkdir(PYLINT_HOME)` can fail when the parent path is missing.
- Expected behavior: create the selected directory recursively before writing stats.
- V2 status: satisfied by `os.makedirs(PYLINT_HOME, exist_ok=True)`.

## F-004: V1 Left Public FAQ Documentation Stale

- Classification: public compatibility/documentation bug found by FVK and fixed in V2.
- Related obligations: PO-7, PO-8.
- Input: user reads `doc/faq.rst` section 3.2 after V1.
- V1 observed behavior: FAQ still says persistent data falls back to the user's `.pylint.d` directory and then current-directory `.pylint.d`.
- Expected behavior: FAQ describes `PYLINTHOME`, absolute `XDG_CACHE_HOME/pylint`, `$HOME/.cache/pylint`, then current-directory `.pylint.d` only when the home directory is not found.
- V2 status: fixed by updating `repo/doc/faq.rst`.

## F-005: Data Directory Versus Cache Directory Is Intent-Ambiguous But Resolved By Public Hint

- Classification: resolved ambiguity, not a code bug.
- Related obligations: PO-2, PO-3.
- Input: persistent stats directory default when no explicit `PYLINTHOME` is set.
- Alternative A: `$HOME/.local/share/pylint`, because the issue initially calls the files "data."
- Alternative B: `$HOME/.cache/pylint`, because the public hint identifies the stored files as non-crucial stats.
- Resolution: choose XDG cache. The implementation stores derived `.stats` pickle files, so the cache hint is the better fit and avoids backing up regenerable analysis data.
- V2 status: V1's cache choice stands.

## Proof-Derived Findings From `/verify`

No additional code bug surfaced in the path-selection claims. The constructed proof covers all selection branches in the intended domain. The only proof-derived repair was F-004: the public documentation branch of the observable behavior did not match the implementation after V1.

