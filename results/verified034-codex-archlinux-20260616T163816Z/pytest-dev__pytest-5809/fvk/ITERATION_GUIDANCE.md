# Iteration Guidance

Status: constructed, not machine-checked.

## Code decision

Keep V1 unchanged. The FVK audit found that the V1 source change discharges the
public issue's core obligation: every paste request produced by `create_new_paste`
uses `lexer=text`.

## Do next in a normal development environment

1. Update public tests that assert the legacy Python lexer so they expect
   `lexer=text`. This was not done here because test edits are forbidden.
2. Run the emitted K commands if a K environment is available:

   ```sh
   cd fvk
   kompile mini-pastebin.k --backend haskell
   kast --backend haskell pastebin-spec.k
   kprove pastebin-spec.k
   ```

3. Run the pytest pastebin tests in a real execution environment. This was not done
   here because the task forbids tests and code execution.

## No additional source edits recommended

No proof obligation requires changing the helper signature, callsites, destination
URL, expiry, payload handling, or response URL extraction. Network and malformed
response behavior remain outside this issue-specific proof boundary.
