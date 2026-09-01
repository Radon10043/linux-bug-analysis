---
name: kernel-commit-message
description: Write or review the commit message for a Linux kernel patch headed upstream — subject line, root-cause narrative, quoted code excerpt, concrete consequence, imperative fix sentence, and trailers (Fixes, Closes, Cc stable, Reported-by, Assisted-by, Signed-off-by). Use when preparing a patch for a kernel mailing list, exporting a vN revision, drafting commit.txt, or auditing an existing message against checkpatch and Documentation/process/submitting-patches.rst.
---

# Kernel Commit Message

## Overview

The patch proves the fix; the commit message has to prove the *bug*. A reviewer
who has never seen the reproducer must be able to read the message alone and
answer: what does the attacker control, which line consumes it unchecked, what
breaks, and why is the fix where it is.

Companion to `linux-kernel-bugfix`, which covers diagnosis and validation. Use
this one when the analysis is done and the message is being written or reviewed.

## Shape

Five parts, in this order.

1. **Subject** — `subsys: <imperative phrase>`, under 75 chars, no trailing
   period. Name the change, not the symptom: `gfs2: reject rgrp bitmaps that do
   not fit in their block`, not `gfs2: fix KASAN use-after-free`. Keep the
   subject **byte-identical across revisions** so threads and CI runs stay
   linked to one patch.

2. **What the untrusted input is.** Which on-disk or userspace field, where it
   is read, and that nothing validates it. One or two sentences.

3. **Which helper consumes it before validating**, as an indented excerpt of
   the real code, followed by why the existing checks do not catch it. The
   excerpt is what makes the claim checkable — keep it short and verbatim.

4. **The concrete consequence.** Name the variable that actually goes wrong and
   give real numbers from the reproducer (block size, field value, how far the
   overrun reaches). Numbers prove the analysis was measured, not imagined.

5. **The fix, in imperative mood**, one sentence. If a reviewer would ask "why
   is the check *there* and not in that branch?", answer it in half a sentence.

Then a blank line, then the trailers.

## Accuracy traps

These are the mistakes that survive a careless draft.

- **"Bypasses the check" vs "the check is inadequate."** If the crafted input
  *satisfies* the existing validation, say so. "Bypass" sends the reviewer
  hunting for a path that skips the check, and there is none.
- **Name the variable that goes wrong.** A message describing an overrun
  without naming the length that got corrupted leaves the consequence
  unmotivated.
- **Do not inherit the KASAN report's vocabulary uncritically.** KASAN labels
  any out-of-bounds access landing on a freed page "use-after-free". If nothing
  was freed and reused — the buffer stayed valid and a length bound was wrong —
  describe the linear overrun and note that KASAN reports it as a UAF. The
  crash title is a signal, not a diagnosis.
- **Consequence, not just detection.** KASAN is the detector. State what
  happens on a kernel without it (an OOB read of N MB, a negative length, a
  lock flood), then mention how it was observed.
- **Justify placement with the reason that actually holds.** Before writing
  "the check sits here because it also covers X", confirm that a check in the
  narrower spot would *not* have caught X. Often it would, and the real reason
  is plainer: one check covering several assignment sites instead of duplicates.
- **A number needs a stated mechanism.** "Nearly 4 GB" is only meaningful once
  the message says the counter is u32 and underflows. Give the mechanism or
  drop the number.

## Trailers

One trailer per line. Never two on one line — this is the single most damaging
formatting slip:

    Fixes: b3b94faa5fe5 ("[GFS2] The core of GFS2")
    Reported-by: syzbot+<hash>@syzkaller.appspotmail.com
    Closes: https://lore.kernel.org/all/<message-id>/
    Cc: stable@vger.kernel.org
    Assisted-by: Claude Code:claude-opus-5
    Signed-off-by: Your Name <you@example.com>

- `Cc: stable@vger.kernel.org` appended to the end of another trailer line means
  **stable never sees the patch**. `Closes:` appended to a `Fixes:` line breaks
  checkpatch's Fixes regex and patchwork's link parsing.
- **Never invent a `Closes:` link.** If the lore Message-ID is not known yet,
  leave a visible placeholder such as `TODO-lore-link` and say so out loud when
  handing the message over. A plausible-looking wrong URL is worse than a gap.
- `Fixes:` is a 12-character SHA plus the exact subject in `("...")`.
- `Assisted-by:` follows the `Tool:model` form used in practice
  (`Assisted-by: Claude Code:claude-opus-5`), even though
  `Documentation/process/coding-assistants.rst` writes it differently.
- `Cc: stable@vger.kernel.org` is right for memory-safety fixes, but a `Fixes:`
  pointing at a subsystem's initial import means every maintained stable tree
  applies. Expect AUTOSEL pickup, and expect some maintainers to argue that
  mounting an untrusted image is already privileged.

### Verifying `Fixes:`

Find where the missing check **never existed**, not where the crash first
became reachable. `git blame` on the call site is routinely misleading — it
points at whichever commit last touched the line.

    git log --diff-filter=A --follow --oneline -- <path>   # when the file arrived
    git grep <field> <sha> -- <path>                       # was a check ever there?
    git describe --contains <sha>                          # first release

Confirm three things before writing the tag: the defective code is present at
that commit verbatim (modulo renames), no later commit removed a check that
used to exist, and the bad path was reachable back then. For a *hang* or
*locking* bug the question is different — find where the slow work moved
*under* the contended lock, not where the slow work appeared.

## Mechanics checkpatch enforces

- **Wrap the log at 75 columns.** `COMMIT_LOG_LONG_LINE`. A reflowed paragraph
  pasted back as one long line is the usual way this regresses.
- **Quoted stack dumps are exempt** — checkpatch sets an internal
  "possible stack dump" flag on a line starting with `BUG:` or `WARNING:` and
  clears it at the **next blank line** (`scripts/checkpatch.pl`, the
  `commit_log_possible_stack_dump` block; ~line 3331 as of 7.3-rc1). Two
  consequences: an indented KASAN excerpt needs no wrapping, and **deleting
  that excerpt means every line in the paragraph must be re-wrapped**.
- **Imperative mood.** `submitting-patches.rst:94` is explicit: "Describe your
  changes in imperative mood, e.g. 'make xyzzy do frotz'". Drop "we can",
  "this patch", "In order to fix this issue".
- Line 2 must be blank; no diff or `---` inside the log body.
- Prefer trimming a stack trace out entirely. Function names in prose
  (`gfs2_rgrp_go_instantiate() then scans it with gfs2_bitfit()`) carry the
  same information without the noise.

## Revisions

- Put the changelog **below the `---`** so it stays out of git history, newest
  first, keeping the whole list. Reference code with version-pinned
  `elixir.bootlin.com` links.
- Export as `vN-0001-<subject>.patch` and keep older revisions.
- Send each revision as a **new top-level thread** addressed to the `M:`
  maintainer and `L:` list from MAINTAINERS. Replying into an old review thread
  buries the patch and leaves CI testing the previous version.
- `RESEND` is reserved for a submission *not modified in any way*
  (`submitting-patches.rst:378`, format `[PATCH Vx RESEND]`). Reflowing the
  message disqualifies it — that is a new version.
- `git format-patch --base=...` so reviewers know what it applies to.

## Checklist

- Subject names the change, under 75 chars, unchanged from the previous revision.
- The untrusted field, the consuming line, and the failing variable are all named.
- At least one real number from the reproducer appears, with its mechanism.
- The fix sentence is imperative, and its placement is justified if non-obvious.
- Every trailer is on its own line; `Signed-off-by:` is present and last.
- `Fixes:` was verified against the source at that commit, not from `git blame`.
- No placeholder (`TODO`, `XXX`) survives, or the hand-off says which remain.
- Every line ≤75 columns outside a quoted `BUG:`/`WARNING:` block.
- The hand-off states plainly whether the patch was built, checkpatch'd, and
  reproduced — never imply verification that did not run.
