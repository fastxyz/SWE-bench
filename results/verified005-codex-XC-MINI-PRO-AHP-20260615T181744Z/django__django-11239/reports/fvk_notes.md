# FVK Notes

## Decision summary

V1 is confirmed and left unchanged. No production source files were edited in
this FVK pass.

## Trace to findings and proof obligations

The original bug is captured as F-001: PostgreSQL `dbshell` did not forward the
mutual TLS parameters from `conn_params` into the `psql` process environment.
PO-001 establishes that those values are already available from
`get_connection_params()`, and PO-004 establishes that V1 maps the four
issue-named keys to the correct libpq environment variables. This justifies
keeping the V1 SSL mapping as the fix.

F-002 confirms that V1 did not disturb existing dbshell behavior. PO-002,
PO-003, PO-005, PO-006, and PO-007 cover the preserved argument order,
`PGPASSWORD` behavior, unrelated environment bindings, SIGINT restoration, and
public call compatibility. This is why I did not refactor the source after V1.

F-003 records an alternative interpretation: forward every libpq option or
replace the argument list with a connection string. I rejected that change
because the public issue specifies the mutual TLS SSL family shown in the
settings example, and PO-007 favors preserving the existing public subprocess
shape unless broader behavior is explicitly required.

F-004 records that the proof is constructed but not machine-checked because the
benchmark forbids running K tooling, Python, or tests. PO-008 remains an
outside-this-session validation obligation, not a reason to withhold the
source fix.

## Artifacts produced

The required artifacts are `fvk/SPEC.md`, `fvk/FINDINGS.md`,
`fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`, and
`fvk/ITERATION_GUIDANCE.md`. I also added the FVK adequacy and formal-core
supporting files under `fvk/` so the no-change decision is traceable to public
intent rather than to V1 behavior alone.
