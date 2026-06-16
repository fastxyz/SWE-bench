# FVK Findings

Status: constructed, not machine-checked.

## F-1: Reported UnicodeError Leak Is Removed

Related obligations: PO-1, PO-2.

Concrete input: `http://.example.com`.

Observed before V1: the ASCII host `.example.com` passed through Requests host
validation and could reach lower IDNA/networking code, producing raw
`UnicodeError: ... label empty or too long`.

Expected from public intent: Requests raises `InvalidURL` with
`URL has an invalid label.`

V2 status: resolved. The ASCII branch now rejects any host beginning with `.`
before URL reconstruction or request sending.

## F-2: Interior Empty ASCII Labels Belong To The Same Issue-Derived Family

Related obligations: PO-3.

Concrete input: `http://example..com`.

Observed before V1: the ASCII branch had no empty-label validation except for
wildcards, so an interior empty label could pass the same branch as the reported
leading empty label.

Expected from public intent: an empty DNS label is an invalid label and should
use the same Requests `InvalidURL` path.

V2 status: resolved by the existing V1 guard `u'..' in host`.

## F-3: The V1 Source Comment Overstated The Empty-Label Guard

Related obligations: PO-6, PO-7.

Concrete input: `http://example.com.`

Observed in V1 source text: the comment said ASCII hosts must not "contain empty
labels", while the code intentionally permits a single trailing dot.

Expected from the FVK spec: the guard rejects leading and interior empty labels,
not the trailing root-label form.

V2 status: resolved by changing the comment to "leading/interior empty labels"
without changing the guard behavior.

## F-4: Full ASCII IDNA Validation Is Not Justified By The Public Intent

Related obligations: PO-5, PO-6, PO-7.

Candidate alternative: call `_get_idna_encoded_host` for every ASCII host, or
otherwise enforce every IDNA hostname rule on the ASCII branch.

Rejected result: that would broaden the fix beyond the empty-label failure and
could reject ASCII hosts that Requests intentionally allowed through unencoded.

Expected from public intent: fix the `UnicodeError` leak for the reported
invalid-label mechanism while preserving the existing ASCII compatibility policy.

V2 status: no source change. V2 keeps the targeted leading/interior empty-label
guard and does not add full ASCII IDNA validation.

## F-5: Proof Is Constructed But Not Machine-Checked

Related obligations: PO-9.

Concrete action not taken: `kompile`, `kast`, and `kprove` were not run.

Expected from task constraints and FVK honesty gate: record the commands and
reason about expected discharge, but do not claim machine-checked proof status.

V2 status: satisfied. The proof artifacts are labeled constructed, not
machine-checked, and no test or formal-tool command was executed.
