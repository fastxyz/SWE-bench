# Public Compatibility Audit

Status: public API and callsite audit for the V1 source change.

C-001. `django.core.management.commands.runserver.Command.handle`

- Change type: internal state value for one parsed input class; no signature change.
- Before for `addrport="0:P", use_ipv6=False`: `self.addr == "0"`.
- After: `self.addr == "0.0.0.0"`.
- Compatibility status: intended behavior change. Public docs say `0` is a shortcut for `0.0.0.0`, and public tests already inspect `self.addr` for other address forms.

C-002. `Command.inner_run`

- Change type: no code change in `inner_run`; it now receives canonical `self.addr`.
- Compatibility status: intended behavior change for startup output; required by E-002.

C-003. `django.core.servers.basehttp.run`

- Change type: no signature change; receives `addr="0.0.0.0"` instead of `addr="0"` for the shortcut.
- Compatibility status: intended alignment with docs. The issue states the bind is effectively `0.0.0.0`; canonicalizing the argument makes the state explicit.

C-004. `django.contrib.staticfiles.management.commands.runserver.Command`

- Change type: subclass inherits the corrected core handling; no override of `handle()` or `inner_run()`.
- Compatibility status: compatible.

C-005. `django.core.management.commands.testserver.Command`

- Change type: delegates `addrport` through `call_command("runserver", addrport=...)`; no option shape change.
- Compatibility status: compatible; delegated shortcut behavior becomes canonical consistently.

C-006. Public tests in `tests/admin_scripts/tests.py`

- Change type: existing assertions for default IPv4, explicit IPv4, port-only input, hostnames, IPv6 defaults, bracketed IPv6, and custom defaults are framed by claims and not intentionally changed.
- Compatibility status: compatible by construction. No tests were run in this environment.

