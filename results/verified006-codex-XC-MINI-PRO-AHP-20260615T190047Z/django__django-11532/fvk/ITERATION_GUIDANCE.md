# Iteration Guidance

Status: V2 source changes are justified by F1 and PO5. No further source edits are recommended for the stated issue.

## Source decisions

1. Keep the V1 cached-hostname normalization, but factor it through `punycode()`.
   - Traces to findings: F2.
   - Traces to proof obligations: PO1, PO2, PO3, PO4.

2. Add `punycode(DNS_NAME)` at the `EmailMessage.message()` `make_msgid()` call site.
   - Traces to findings: F1.
   - Traces to proof obligations: PO2, PO5.

3. Do not alter explicit `Message-ID` header handling.
   - Traces to proof obligations: PO6, PO7.

4. Do not add invalid-hostname fallback behavior in this patch.
   - Traces to findings: F3.
   - Reason: the public issue specifies valid Unicode hostnames and expected IDNA conversion, not invalid-IDNA error policy.

## Suggested tests for a normal development environment

Do not edit tests in this benchmark task. In a normal Django development pass, add or keep tests for:

- `socket.getfqdn()` returning a valid non-ASCII hostname, with `EmailMessage.encoding = "iso-8859-1"`, asserting the generated `Message-ID` contains the punycoded domain.
- `django.core.mail.message.DNS_NAME` temporarily replaced with `"漢字"`, asserting the generated `Message-ID` contains `"xn--p8s937b"`.
- ASCII hostname preservation.
- Explicit `Message-ID` override behavior.

## Verification follow-up

Run the commands in `PROOF.md` in an environment with K installed before treating tests as redundant. Until `kprove` returns `#Top`, keep the tests.
