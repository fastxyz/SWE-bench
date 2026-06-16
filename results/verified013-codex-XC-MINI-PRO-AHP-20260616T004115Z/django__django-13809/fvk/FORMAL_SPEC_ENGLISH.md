# Formal Spec In English

Status: constructed, not machine-checked.

## Claim: RUNSERVER-PARSER-HAS-SKIP-CHECKS

When the core `runserver` command builds its command-specific parser options, the resulting option list contains the existing `addrport`, `--ipv6`, `--nothreading`, and `--noreload` options plus a `--skip-checks` option.

## Claim: INNERRUN-NO-SKIP-CHECKS

When `runserver.inner_run()` is entered with `skip_checks` false, it first performs the pre-existing autoreload exception check, then performs Django system checks, then performs migration checks, and then proceeds to server startup.

## Claim: INNERRUN-SKIP-CHECKS

When `runserver.inner_run()` is entered with `skip_checks` true, it first performs the pre-existing autoreload exception check, then skips Django system checks, then still performs migration checks, and then proceeds to server startup.

## Frame Conditions

- No command method signature changes.
- No change to address/port parsing, threading, reloader, IPv6, handler construction, socket error handling, keyboard interrupt handling, or staticfiles handler wrapping.
- The staticfiles `runserver` subclass inherits the new parser option through its existing `super().add_arguments(parser)` call.
