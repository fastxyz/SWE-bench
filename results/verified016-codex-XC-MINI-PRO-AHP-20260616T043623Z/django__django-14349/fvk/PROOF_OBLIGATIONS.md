# PROOF OBLIGATIONS

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## PO-001: Intent adequacy for unsafe characters

Statement: LF, CR, and tab are invalid characters for `URLValidator` input and must not be silently stripped before validation succeeds.

Evidence: SPEC E-003 and E-005.

Formal claim: C-UNSAFE in `fvk/urlvalidator-spec.k`.

Discharge: V1 checks `any(char in value for char in self.unsafe_chars)` with `unsafe_chars = frozenset('\t\r\n')` before any branch that calls `urlsplit()`.

Status: discharged by source inspection and constructed claim.

## PO-002: Reported examples reject

Statement: `http://www.djangoproject.com/\n` and `http://[::ffff:192.9.5.5]\n` raise `ValidationError`.

Evidence: SPEC E-004 and E-005.

Formal claim: C-UNSAFE.

Discharge: both example strings contain LF, a member of `unsafe_chars`.

Status: discharged by source inspection and constructed claim.

## PO-003: Unsafe-character family completeness

Statement: V1 must cover all publicly named characters affected by bpo-43882 stripping: LF, CR, and tab.

Evidence: SPEC E-003.

Formal claim: `hasUnsafe(V)` is the abstraction of membership in `{TAB, CR, LF}`; C-UNSAFE rejects all `hasUnsafe(V)`.

Discharge: the source literal `'\t\r\n'` contains tab, carriage return, and line feed.

Status: discharged.

## PO-004: Branch priority over `urlsplit()`

Statement: unsafe-character rejection must occur before `urlsplit()` or `urlunsplit()` can normalize the input.

Evidence: SPEC E-003, FINDINGS F-001.

Formal claim: C-UNSAFE must rewrite directly to `VE` with no dependency on `splitOK(V)` or fallback predicates.

Discharge: source order is type check, unsafe-character check, scheme check, regex, then fallback `urlsplit()`.

Status: discharged.

## PO-005: Frame condition for values without unsafe characters

Statement: for strings without LF, CR, or tab, V1 must preserve the pre-existing URL validation decision procedure.

Evidence: SPEC E-002 and E-006.

Formal claim: C-NO-UNSAFE-FRAME.

Discharge: if the new guard is false, execution continues to the existing scheme, regex, IDN fallback, IPv6, and hostname-length code unchanged.

Status: discharged.

## PO-006: IPv6 handling not separately changed

Statement: the fix for the reported IPv6 newline case should come from unsafe-character rejection, not from weakening or bypassing IPv6 validation.

Evidence: SPEC E-002 and E-004.

Formal claim: C-HOST-REJECT plus C-UNSAFE.

Discharge: strings with LF reject before IPv6 parsing; strings without LF still reach the existing IPv6 validation branch.

Status: discharged.

## PO-007: Public compatibility

Statement: V1 must not change public constructor signature, validator call shape, success/failure shape, or form/model field integration.

Evidence: SPEC E-006 and E-007.

Formal claim: PC-001 through PC-005 in SPEC.

Discharge: source diff only adds a class attribute and an early validation guard in `__call__()`; no callsites, signatures, or tests changed.

Status: discharged.

## PO-008: Model adequacy for the reported property

Statement: the K model must distinguish unsafe-character inputs from otherwise identical sanitized inputs.

Evidence: FVK method property-completeness requirement; SPEC A-005.

Formal claim: C-UNSAFE uses `hasUnsafe(V)` directly and C-NO-UNSAFE-FRAME applies only when `hasUnsafe(V)` is false.

Discharge: the passing/failing discriminator is represented: `V = "http://www.djangoproject.com/\n"` has `hasUnsafe(V) = true`, while the sanitized URL without LF has `hasUnsafe(V) = false`.

Status: discharged for the issue property.

## PO-009: Proof honesty and residual risk

Statement: the proof must not claim machine-checked confidence or full URL syntax verification.

Evidence: FVK verify honesty gate.

Formal claim: all artifacts are labeled "constructed, not machine-checked"; broad URL syntax is kept as a proof boundary.

Discharge: PROOF records commands to run later and FINDINGS F-006 keeps broader tests.

Status: discharged.
