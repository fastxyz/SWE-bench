# Findings

Status: FVK audit findings, including proof-derived findings. Constructed, not machine-checked.

F-001. Legacy startup URL used the documented shortcut literally.

- Classification: code bug, fixed by V1.
- Input: `addrport="0:8000"`, `use_ipv6=False`.
- Observed before V1: `self.addr == "0"` and startup output `Starting development server at http://0:8000/`.
- Expected from E-001 through E-004: `self.addr == "0.0.0.0"` and startup output `Starting development server at http://0.0.0.0:8000/`.
- Proof obligations: PO-001, PO-002, PO-003.
- V1/V2 status: satisfied by the normalization at `runserver.py` line 106.

F-002. Display-only normalization would leave a public state mismatch.

- Classification: proof-derived design finding.
- Input: `addrport="0:8000"`, `use_ipv6=False`.
- Candidate alternative: change only `inner_run()` display to print `0.0.0.0` while leaving `self.addr == "0"`.
- Why rejected: E-007 shows public tests inspect `Command.addr`; E-008 shows the same state feeds the bind call. Display-only output would satisfy the issue string but not the documented equivalence of `0:port` and `0.0.0.0:port`.
- Proof obligations: PO-003 and PO-009.
- V1/V2 status: V1 correctly normalizes the stored address.

F-003. `--ipv6 0:port` is underspecified.

- Classification: underspecified intent, no V2 source change.
- Input: `addrport="0:8000"`, `use_ipv6=True`.
- Existing/V1 behavior: `0` remains on the hostname/FQDN path rather than being rewritten to `0.0.0.0`.
- Expected: not determined by public evidence. E-005 names `::` as the IPv6 wildcard; E-006 says `--ipv6` changes defaults to IPv6; the issue and tutorial example are non-IPv6.
- Proof obligations: PO-007 and PO-008.
- V1/V2 status: preserved existing behavior; future clarification could decide whether to reject or reinterpret this input.

F-004. The K model abstracts the regex parser and long-running server.

- Classification: proof capability gap / escalation boundary, not a code bug.
- Scope: `naiveip_re`, settings validation, autoreload, system checks, migration checks, `get_handler()`, socket creation, and `serve_forever()` are not fully modeled.
- Reason: the issue is on the post-parse address normalization and startup URL observable. The parser already accepts `0:8000`, and the server intentionally runs indefinitely.
- Proof obligations: PO-010.
- V1/V2 status: no source change; keep integration tests and do not remove tests based on this constructed proof alone.

F-005. No execution or machine checking was performed.

- Classification: verification environment constraint.
- Evidence: task forbids running tests, Python, `kompile`, or `kprove`.
- Expected next step outside this environment: run the emitted commands in `PROOF.md` and add/keep conventional tests as described in `ITERATION_GUIDANCE.md`.
- Proof obligations: PO-010.
