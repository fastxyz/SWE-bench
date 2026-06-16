# Baseline Notes

## Root Cause

`runserver` parses the optional `addrport` argument in `django/core/management/commands/runserver.py` and stores the address in `self.addr`. The value is then reused for both the socket bind and the "Starting development server at ..." message.

The documented shortcut `0:8000` was accepted by the existing parser as a hostname-like address of `"0"`, but it was never canonicalized to the equivalent wildcard IPv4 address, `"0.0.0.0"`. As a result, the development server startup message printed `http://0:8000/`, which is not consistently usable as a browser URL even though the bind works as a wildcard address on affected systems.

## Changed Files

`repo/django/core/management/commands/runserver.py`

Normalized the parsed non-IPv6 address `"0"` to `"0.0.0.0"` before `inner_run()` formats the startup URL and before the server is started. This keeps the command's internal address, displayed URL, and documented behavior aligned for `python manage.py runserver 0:8000`.

`reports/baseline_notes.md`

Added this report with the root cause, changed-file summary, assumptions, and rejected alternatives required by the benchmark task.

## Assumptions and Alternatives

I treated `0` as the documented IPv4 wildcard shortcut only when `--ipv6` is not active. With `--ipv6`, the existing parser treats `0` as an FQDN-like value, and changing that behavior was outside the reported issue.

I considered changing only the displayed URL in `inner_run()`, but rejected that because it would leave `self.addr` as `"0"` while printing `"0.0.0.0"`. Canonicalizing once during argument handling is more direct and keeps the bind value and display value consistent.

I considered modifying the regular expression to add a dedicated `0` capture group, but rejected that as a larger parser change than necessary. The existing parser already accepts the input; the bug is the missing normalization after parsing.
