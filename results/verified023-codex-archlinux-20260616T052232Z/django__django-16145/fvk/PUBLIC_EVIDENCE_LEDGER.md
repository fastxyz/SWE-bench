# Public Evidence Ledger

E-001

- Source: prompt/problem
- Evidence: "According to tutorial running python manage.py runserver 0:8000 is the same as python manage.py runserver 0.0.0.0:8000"
- Obligation: Treat non-IPv6 `0:port` as equivalent to `0.0.0.0:port`.
- Status: Encoded by SPEC S-001 and claim `BUGFIX-ZERO-SHORTCUT`.

E-002

- Source: prompt/problem
- Evidence: "Starting development server at http://0:8000/" is unusable in some browsers; "Output should be ... http://0.0.0.0:8000/"
- Obligation: Startup output must render `0.0.0.0`, not `0`, for the documented shortcut.
- Status: Encoded by SPEC S-002 and claim `BUGFIX-ZERO-SHORTCUT`.

E-003

- Source: public hint
- Evidence: "it would be reasonable to rewrite an address of 0 (zero) to 0.0.0.0 in runserver's output"
- Obligation: The observable URL is the primary symptom; canonical address display is acceptable public behavior.
- Status: Encoded by SPEC S-002.

E-004

- Source: tutorial docs
- Evidence: "`0` is a shortcut for `0.0.0.0`."
- Obligation: The shortcut is not merely a browser workaround; it is documented command behavior.
- Status: Encoded by SPEC S-001 and S-003.

E-005

- Source: command reference docs
- Evidence: To make the server visible to other machines, use an IP such as `192.168.2.1`, `0.0.0.0`, or `::` with IPv6 enabled.
- Obligation: IPv4 wildcard and IPv6 wildcard are distinct documented forms.
- Status: Encoded by frame condition S-007; supports preserving `--ipv6` behavior for `0`.

E-006

- Source: command reference docs
- Evidence: "`--ipv6, -6` uses IPv6 for the development server. This changes the default IP address from `127.0.0.1` to `::1`."
- Obligation: Do not regress IPv6 default handling or bracketed IPv6 display.
- Status: Encoded by claims `FRAME-DEFAULT-IPV6` and `FRAME-BRACKETED-IPV6`.

E-007

- Source: public tests
- Evidence: `ManageRunserver.assertServerSettings()` checks `cmd.addr`, `cmd.port`, `cmd.use_ipv6`, and `cmd._raw_ipv6`.
- Obligation: `self.addr` is a public test surface; a display-only fix would leave state inconsistent with the documented shortcut.
- Status: Encoded by SPEC S-003 and finding F-002.

E-008

- Source: implementation
- Evidence: `inner_run()` formats the startup URL from `self.addr`, `self.port`, and `_raw_ipv6`; `run()` receives the same `self.addr`.
- Obligation: Normalizing `self.addr` before `inner_run()` proves both display and bind use the same canonical value.
- Status: Encoded by proof obligation PO-003.

E-009

- Source: implementation/callsite audit
- Evidence: `django.contrib.staticfiles.management.commands.runserver.Command` subclasses core `RunserverCommand`; `testserver` delegates to `call_command("runserver", addrport=...)`.
- Obligation: Do not change signatures or option shape; subclass and delegating commands should inherit the corrected behavior.
- Status: Encoded by PUBLIC_COMPATIBILITY_AUDIT C-002 and C-003.

