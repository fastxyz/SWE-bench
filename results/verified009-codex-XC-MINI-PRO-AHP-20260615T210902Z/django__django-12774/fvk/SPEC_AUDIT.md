# Spec Audit

Status: constructed, not machine-checked.

CLAIM-ACCEPT-PK: pass. The formal claim preserves pre-existing primary-key
behavior and does not conflict with the issue.

CLAIM-ACCEPT-UNIQUE: pass. The formal claim preserves pre-existing
`unique=True` behavior.

CLAIM-ACCEPT-CONSTRAINT-NAME: pass. It directly encodes issue evidence E1 and
E2.

CLAIM-ACCEPT-CONSTRAINT-ATTNAME: pass. It is entailed by source evidence E7
that Django accepts both field names and attnames as local field identifiers.

CLAIM-REJECT-NON-UNIQUE: pass. It preserves the public error behavior for
fields that are not unique by themselves.

Composite constraint rejection: pass. The issue asks for fields unique by total
`UniqueConstraint`; a composite constraint makes a tuple unique, not a single
field key.

Conditional constraint rejection: pass. `Options.total_unique_constraints`
excludes conditional constraints and the issue says "total".

Frame condition: pass. The source edit is confined to validation; no public
intent requires changing query execution or returned dictionary construction.
