# Intent Spec

Status: intent-only, written before accepting the V1 implementation as correct.

## Required Behavior

I-001. For `python manage.py runserver 0:8000` without `--ipv6`, `0` is the documented shortcut for `0.0.0.0`.

I-002. The startup line must present the canonical, browser-usable URL `http://0.0.0.0:8000/`, not `http://0:8000/`.

I-003. The same canonical address should be used consistently by the command state that feeds the startup line and the later server bind. Public tests inspect `Command.addr`, so the state is part of the public test surface even though it is not a documented command-line API.

I-004. Existing documented and public-tested address forms remain unchanged: omitted address uses `127.0.0.1`, port-only input uses the default address, explicit IPv4 addresses stay explicit, hostnames stay hostnames, bracketed IPv6 addresses display with brackets, and `--ipv6` changes the default address to `::1`.

I-005. `--ipv6 0:8000` is not specified by the issue or tutorial. The command reference names `::` as the IPv6 wildcard and separately allows ASCII hostnames. This audit treats that case as underspecified and preserves existing hostname/FQDN behavior.

## Domain and Frame Conditions

The verified domain is the reduced, already-parsed `runserver` address space relevant to `Command.handle()` and the startup line in `Command.inner_run()`: missing `addrport`, port-only input, `addr:port` with IPv4/FQDN/bracketed IPv6, and the documented non-IPv6 shortcut `0:port`.

Invalid `addrport` strings, settings validation, system checks, migrations checks, autoreload, socket availability, and the infinite server loop are outside the proof model. They are frame conditions: this fix must not alter their code paths.

