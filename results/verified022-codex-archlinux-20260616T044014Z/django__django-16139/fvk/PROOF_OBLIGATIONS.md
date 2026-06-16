# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-1 - Saved Instance Help Link Uses Admin-Quoted Primary Key

Formal claim: `helpRel(hasPk(PK)) => pkPasswordRel(adminQuote(PK))`.

Intent source: E-2, E-3, E-5.

Precondition: `self.instance.pk is not None` and the password field exists.

Postcondition: the relative link carries the admin-quoted primary key segment,
not the current object URL segment.

Status: discharged by direct symbolic rewrite of V1's saved-instance branch in
`fvk/user-change-form-spec.k`.

## PO-2 - to_field Change URL Resolves to Primary-Key Password URL

Formal claim: `adminPasswordKey(hasPk(PK), ROOT, TOFIELD) => PK` when
`adminUnquote(TOFIELD) =/= PK`.

Intent source: E-1, E-2, E-3.

Precondition: saved user, current change URL object segment is a non-pk
`to_field` value, and the password field exists.

Postcondition: resolving the help link and then interpreting the password URL's
object segment yields the primary key `PK`.

Status: discharged by composing PO-1, `resolve(changeUrl(ROOT, TOFIELD),
pkPasswordRel(adminQuote(PK)))`, and
`adminUnquote(adminQuote(PK)) => PK`.

## PO-3 - Primary-Key Change URL Compatibility

Formal claim: `adminPasswordKey(hasPk(PK), ROOT, adminQuote(PK)) => PK`.

Intent source: E-4, E-5.

Precondition: saved user reached through the ordinary primary-key admin change
URL and the password field exists.

Postcondition: resolving the help link reaches the same password key `PK` that
the existing public admin test expects.

Status: discharged by the same composition as PO-2 with the current object
segment already equal to `adminQuote(PK)`.

## PO-4 - Unsaved Instance Fallback

Formal claim: `helpRel(noPk()) => oldPasswordRel()`.

Intent source: E-6.

Precondition: `self.instance.pk is None` and the password field exists.

Postcondition: the help text keeps the previous `../password/` relative link
shape rather than emitting a `None` primary-key segment.

Status: discharged by direct symbolic rewrite of V1's fallback branch.

## PO-5 - Admin Quote Inverse Side Condition

Formal claim: `adminUnquote(adminQuote(PK)) => PK`.

Intent source: E-5 and the implementation pairing of
`django.contrib.admin.utils.quote()`/`unquote()`.

Precondition: `PK` is an admin object-id value in the supported Django admin
path-segment domain.

Postcondition: the password view receives the original primary key after
unquoting the URL segment.

Status: used as a simplification axiom in `fvk/mini-admin-url.k`; not separately
machine-checked in this session.

## PO-6 - Compatibility Frame Conditions

Formal claim: no constructor signature, virtual dispatch protocol, password
field absence behavior, user-permissions queryset behavior, or unsaved-instance
behavior changes.

Intent source: E-6, E-7, and code inspection of the unchanged branches around
the V1 edit.

Precondition: public code instantiates `UserChangeForm` directly, subclasses it,
or excludes `password`.

Postcondition: those uses continue through the same public API shape; only the
saved-instance password help URL changes.

Status: discharged by source inspection. This frame condition is outside the
mini URL model.

## PO-7 - Machine Check Commands Are Deferred

The exact commands to machine-check the constructed artifacts later are:

```sh
kompile fvk/mini-admin-url.k --backend haskell
kast --backend haskell fvk/user-change-form-spec.k
kprove fvk/user-change-form-spec.k
```

Expected machine-check outcome if the constructed claims and mini semantics are
accepted by K: `#Top`.

Status: not executed, by task instruction.
