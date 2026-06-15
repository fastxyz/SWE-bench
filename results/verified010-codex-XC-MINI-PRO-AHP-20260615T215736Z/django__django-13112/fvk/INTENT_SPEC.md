# Intent Spec

Status: constructed, not machine-checked.

1. Mixed-case installed app labels must remain case-sensitive in migration relation references.
2. A lazy relation to `DJ_RegLogin.Category` must serialize to `DJ_RegLogin.category`, not `dj_reglogin.category`.
3. Model names continue to use Django's lowercase model-key convention.
4. Concrete model references continue to use `_meta.label_lower`.
5. The fix must be local to production source and must not modify test files or public field APIs.

