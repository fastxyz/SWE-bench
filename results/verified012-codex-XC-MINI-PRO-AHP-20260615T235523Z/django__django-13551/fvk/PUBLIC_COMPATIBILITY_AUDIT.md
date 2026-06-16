# Public Compatibility Audit

Status: no unhandled public compatibility issues found.

## Changed symbol

`PasswordResetTokenGenerator._make_hash_value(user, timestamp)`

- Publicness: private helper by naming convention, but subclasses may override
  it.
- Signature: unchanged.
- Return type: unchanged string HMAC input.
- Dispatch shape: unchanged; callers still call `_make_hash_value(user,
  timestamp)`.
- Compatibility result: compatible for callers and overrides that follow the
  existing signature.

## Public callers

`PasswordResetTokenGenerator.make_token(user)`

- Signature unchanged.
- Behavior preserved for unchanged user state except that the email component is
  now part of the state.

`PasswordResetTokenGenerator.check_token(user, token)`

- Signature unchanged.
- Existing malformed-token, timeout, secret, and legacy-algorithm branches are
  unchanged.

`PasswordResetForm.save(..., token_generator=default_token_generator)`

- Call shape unchanged: still calls `token_generator.make_token(user)`.
- The form already selects the recipient via `UserModel.get_email_field_name()`,
  consistent with the V1 hash selection.

`PasswordResetConfirmView`

- Call shape unchanged: still calls `self.token_generator.check_token(self.user,
  token)`.

## Subclasses and overrides

In-tree public tests define a `MockedPasswordResetTokenGenerator` subclass that
overrides `_now()` only. The V1 patch does not affect that override.

No in-tree override of `_make_hash_value()` was found. If a third-party subclass
overrides `_make_hash_value()`, Django already treats the method as the extension
point for custom token state; the unchanged signature keeps the override
compatible, though such subclasses must opt into the new email invalidation
behavior themselves.
