# FVK Proof

Status: constructed, not machine-checked.

## Summary

The constructed proof covers the password help link produced by V1
`UserChangeForm.__init__()`. For any saved instance, the link is specified to
resolve to the password URL keyed by the instance primary key, regardless of
whether the current change URL was addressed by primary key or by a different
`to_field` value.

## Proof of PO-1

Starting state: `helpRel(hasPk(PK))`.

The mini semantics rule for the saved-instance branch rewrites:

```k
helpRel(hasPk(PK)) => pkPasswordRel(adminQuote(PK))
```

This matches V1's branch:

```python
if self.instance.pk is not None:
    from django.contrib.admin.utils import quote
    password_url = "../../%s/password/" % quote(self.instance.pk)
```

Therefore the generated saved-instance relative link carries
`adminQuote(PK)`.

## Proof of PO-2

Starting state:

```k
adminPasswordKey(hasPk(PK), ROOT, TOFIELD)
```

with side condition `adminUnquote(TOFIELD) =/= PK`.

Symbolic execution expands the composition:

```k
passwordKey(resolve(changeUrl(ROOT, TOFIELD), helpRel(hasPk(PK))))
```

By PO-1, `helpRel(hasPk(PK))` rewrites to
`pkPasswordRel(adminQuote(PK))`.

Relative resolution then rewrites:

```k
resolve(changeUrl(ROOT, TOFIELD), pkPasswordRel(adminQuote(PK)))
=> passwordUrl(ROOT, adminQuote(PK))
```

The password-view key extraction rewrites:

```k
passwordKey(passwordUrl(ROOT, adminQuote(PK)))
=> adminUnquote(adminQuote(PK))
```

By PO-5, `adminUnquote(adminQuote(PK)) => PK`. Thus the resolved password URL is
interpreted as the primary key `PK`, not as the non-pk `TOFIELD` segment.

The contrast claim for the pre-fix link rewrites
`oldAdminPasswordKey(ROOT, TOFIELD)` to `adminUnquote(TOFIELD)`. Under the
issue condition where that value is not `PK`, the old link targets the wrong
password key. That constructs the reported 404 mechanism.

## Proof of PO-3

Starting state:

```k
adminPasswordKey(hasPk(PK), ROOT, adminQuote(PK))
```

The same rewrites as PO-2 apply, with the current object segment already equal
to the quoted primary key. The result is still:

```k
adminUnquote(adminQuote(PK)) => PK
```

This preserves the public primary-key admin behavior.

## Proof of PO-4

Starting state: `helpRel(noPk())`.

The fallback rule rewrites:

```k
helpRel(noPk()) => oldPasswordRel()
```

This matches V1's initialization of `password_url = "../password/"` before the
saved-instance branch. Therefore unsaved instances keep the old relative link
shape and do not produce a `None` path segment.

## Proof of PO-6

This is a source-inspection frame proof rather than a K URL claim.

`UserChangeForm.__init__()` keeps the same signature, still calls
`super().__init__(*args, **kwargs)`, still obtains `password` with
`self.fields.get("password")`, and still updates `user_permissions.queryset`
after the password-help block. The code path for subclasses without a password
field is guarded by the same `if password:` condition. The no-pk path is covered
by PO-4.

## Residual Risk

The K artifacts model only the URL/link construction relevant to the issue. They
do not model Django's full template rendering, HTTP router, permissions, form
validation, database behavior, or translation machinery.

The proof is constructed but not machine-checked. The task forbids running K
tooling, tests, Python, or Django code. The commands in PO-7 should be run before
claiming machine-verified proof or removing any tests.

## Test Guidance

After a successful K machine check, a unit assertion that joins the generated
relative link from a primary-key change URL to the password-change URL would be
subsumed by PO-3. Integration tests should still be kept because this proof
abstracts routing, rendering, and database lookup.

No tests were edited.
