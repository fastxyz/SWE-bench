# Iteration Guidance

Status: constructed, not machine-checked.

## Code Decision

Apply V2, not V1 unchanged.

Reason: F-2 and PO-2 show that V1 fixed the visible qop quoting field but left the digest qop-value tied to the raw options string. V2 makes the selected token explicit in the digest input.

## Follow-Up Tests To Add In A Normal Test Environment

- Unit test: qop `auth` produces an Authorization header containing `qop="auth"`.
- Unit test: qop `auth,auth-int` produces a digest response based on selected qop `auth`, not the raw options string.
- Unit test: qop `auth-int, auth` with whitespace still selects `auth`.
- Existing live/integration digest tests should be kept because the FVK proof does not cover network behavior, cookie handling, rewinds, or connection reuse.

## Remaining Open Boundary

`auth-int` support remains unimplemented. A future change that claims full RFC2617 qop support should define the entity-body hash behavior, decide how streaming request bodies are handled, and then add a separate FVK proof obligation rather than relying on this qop-quoting proof.

## Commands Recorded For Future Machine Checking

```sh
cd fvk
kompile mini-python.k --backend haskell
kast --backend haskell digest-auth-spec.k
kprove digest-auth-spec.k
```

Expected result after a future machine-checking run: `#Top` for the three qop claims.

