# Spec Audit

Status: adequacy gate for the constructed spec.

| Formal claim | Intent entry | Audit |
| --- | --- | --- |
| K1 configured email included | I1, I2, I3; ledger E1, E2, E4, E5 | Pass. This is exactly the issue fix and uses Django's public email-field hook. |
| K2 missing email defined | I4; ledger E3 | Pass. The prompt explicitly warns that `AbstractBaseUser` need not have an email. |
| K3 null-like email defined as empty | I4; ledger E3 plus default no-address convention | Pass with named assumption. Public intent requires no concrete email not to break token generation; it does not require distinguishing null from empty. |
| K4 same-state validation | I5; ledger E6, E7 | Pass. This preserves existing token behavior for unchanged state. |
| K5 email change rejected | I1, I2; ledger E1, E2 | Pass. This is the primary reported bug. |
| K6 password change rejected | I5; ledger E6, E7 | Pass. Existing invalidator preserved as a frame condition. |
| K7 expired token rejected | I5; ledger E6, E7 | Pass. Existing timeout behavior preserved as a frame condition. |

No formal-English claim is weaker than the public intent for the issue. No
claim relies only on the V1 implementation as expected behavior; implementation
facts are used to model transition shape and frame conditions.
