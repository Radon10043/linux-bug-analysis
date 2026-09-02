---
name: kernel-commit-message
description: Write or review the commit message for a Linux kernel patch headed upstream — subject line, root-cause narrative, quoted code excerpt, concrete consequence, imperative fix sentence, and trailers (Fixes, Closes, Cc stable, Reported-by, Assisted-by, Signed-off-by). Use when preparing a patch for a kernel mailing list, exporting a vN revision, drafting commit.txt, or auditing an existing message against checkpatch and Documentation/process/submitting-patches.rst.
---

# Kernel Commit Message

## Overview

The patch proves the fix; the commit message has to prove the *bug*. A reviewer
who has never seen the reproducer must be able to read the message alone and
answer: what assumption did the code make, what broke it, and why is the fix
where it is.

Companion to `linux-kernel-bugfix`, which covers diagnosis and validation. Use
this one when the analysis is done and the message is being written or reviewed.

## Write it short the first time

The failure mode of a first draft is not vagueness, it is length. Everything
learned during debugging wants into the message; almost none of it belongs.
Aim for **four paragraphs, roughly 25-35 lines of log**, readable start to
finish by a kernel developer who has never opened this filesystem or driver.

Two tests for every sentence before it stays:

- **Does deleting it weaken the proof that the bug is real?** If not, delete it.
- **Would a reader outside this subsystem have to look something up to parse
  it?** If yes, either explain the concept in half a clause or cut the sentence.

What goes, specifically — each of these has had to be trimmed out of a draft:

- The reproducer's itinerary: which ioctl argument, which group, which bitmap
  block, which error code came back. The *mechanism* stays, the trip does not.
- Waypoint function names. `nilfs_ioctl_free_vblocknrs()` calling
  `nilfs_palloc_freev()` is navigation, not evidence. Name only the functions
  that make or break the assumption.
- The quoted stack dump. `Closes:` already points at the full report.
- Second-order damage ("and then this state is never cleaned up") unless the
  fix's justification depends on it — see the consequence trap below.
- Numbers, unless the consequence is unintelligible without them. `u32
  underflow reaching nearly 4 GB` needs its number; `several blocks share a
  folio` does not. An earlier version of this skill demanded a reproducer
  number in every message; that produced padding. Include one when it carries
  the mechanism, otherwise leave it in the bug report.

Brevity is not vagueness: every claim that survives must still be checkable
against the source, and the excerpt is what makes it checkable.

## Shape

Four parts, in this order.

1. **Subject** — `subsys: <imperative phrase>`, under 75 chars, no trailing
   period. Name the change, not the symptom: `gfs2: reject rgrp bitmaps that do
   not fit in their block`, not `gfs2: fix KASAN use-after-free`. Keep the
   subject **byte-identical across revisions** so threads and CI runs stay
   linked to one patch.

2. **The assumption**, in plain terms — what the code is trying to do and what
   it takes for granted, ending at the check or the consumer that fails. Open
   with the purpose, not the call chain: "while GC runs, nilfs2 keeps a shadow
   copy of the DAT file's page cache so it can roll back" orients a stranger in
   one line. Then the short **verbatim excerpt** of the line that assumes it.

3. **Why the assumption does not hold.** For an unvalidated input: which
   on-disk or userspace field, and which helper consumes it before validating.
   For a regression: which commit made the guarantee best-effort, quoted as
   `commit <sha12> ("subject")`. Then the mechanism that produces the bad state
   — the two or three facts that have to be true at once, stated as facts about
   the code, not as a replay of the reproducer.

4. **The fix, in imperative mood**, one or two sentences. If a reviewer would
   ask "why is the check *there* and not in that branch?", or if the obvious
   alternative is to revert the commit named in `Fixes:`, answer in half a
   sentence — `rather than making nilfs_clear_folio_dirty() force-clear busy
   buffer heads again` is what tells the author of that commit you did not
   undo their fix.

Then a blank line, then the trailers.

## Accuracy traps

These are the mistakes that survive a careless draft.

- **"Bypasses the check" vs "the check is inadequate."** If the crafted input
  *satisfies* the existing validation, say so. "Bypass" sends the reviewer
  hunting for a path that skips the check, and there is none.
- **Name the variable or flag that goes wrong.** A message describing an
  overrun without naming the length that got corrupted, or a warning without
  naming the state that was supposed to be cleared, leaves the reader guessing.
- **Do not inherit the report's vocabulary uncritically.** KASAN labels any
  out-of-bounds access landing on a freed page "use-after-free". If nothing was
  freed and reused — the buffer stayed valid and a length bound was wrong —
  describe the linear overrun. The crash title is a signal, not a diagnosis.
- **State the consequence, not just the detector,** in one clause: an OOB read
  of N MB, a negative length, a lock flood, a folio left dirty with no dirty
  buffer under it. One case needs no such clause: when the kernel already
  asserts the invariant, the assertion firing *is* the consequence, and naming
  the state that was supposed to be clean is enough — the maintainer wrote that
  assertion precisely because the state is invalid. Keep the downstream damage
  (what the bad state goes on to break) out of the message but ready to send:
  it is the answer to "then why not just delete the `WARN_ON`", and it is what
  defends `Cc: stable` if the thread questions it.
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
- **`Reported-by:` only credits someone else.** A bug found by our own fuzzing
  and reported to the list by the patch author gets `Closes:` pointing at that
  mail and no `Reported-by:`; a syzbot report gets both.
- `Fixes:` is a 12-character SHA plus the exact subject in `("...")`.
- `Assisted-by:` follows the `Tool:model` form used in practice
  (`Assisted-by: Claude Code:claude-opus-5`), even though
  `Documentation/process/coding-assistants.rst` writes it differently.
- `Cc: stable@vger.kernel.org` is right for memory-safety fixes and for state
  corruption, but a `Fixes:` pointing at a subsystem's initial import means
  every maintained stable tree applies. Expect AUTOSEL pickup, and expect some
  maintainers to argue that mounting an untrusted image is already privileged.

### Verifying `Fixes:`

Find where the missing check **never existed**, not where the crash first
became reachable. `git blame` on the call site is routinely misleading — it
points at whichever commit last touched the line.

    git show <sha>^:<path> | sed -n '/<func>/,/^}/p'   # was the guard there?
    git log --oneline <sha>..HEAD -- <path>            # who touched it since?
    git log --diff-filter=A --follow --oneline -- <path>
    git describe --contains <sha>                      # first release

Confirm three things before writing the tag, in these words:

1. The defect is present at that commit — for a regression, the guarantee the
   code relies on existed at `<sha>^` and the commit removed it. An early
   `return` added to a helper is the usual shape.
2. No later commit removed or restored a check in between. Enumerate every
   commit touching the file since `<sha>` and check each one.
3. The bad path was already reachable then — the assertion that fires, and the
   other preconditions, predate `<sha>`.

Two traps:

- **A sibling fix in the same file is not automatically your `Fixes:`.** A
  recent nearby commit may be fixing the *opposite* direction of the same
  invariant (state wrongly cleared vs. state wrongly kept). Read its message
  before inheriting its tag.
- For a **hang or locking** bug the question is different — find where the slow
  work moved *under* the contended lock, not where the slow work appeared.

## Mechanics checkpatch enforces

- **Cite a commit in the body as `commit <sha12+> ("subject")`.** A bare SHA in
  prose is a checkpatch **ERROR** (`GIT_COMMIT_ID`), and it is easy to hit when
  a sentence starts "this has been best-effort since ca76bb226bf4". The word
  `commit` is required in prose; the `Fixes:` trailer takes the SHA bare.
- **Run checkpatch from inside the kernel tree.** From elsewhere it cannot
  resolve the `Fixes:` SHA and emits a spurious
  `WARNING: Unknown commit id ..., maybe rebased or not pulled?`. Do not chase
  that warning — re-run with the tree as the working directory.
- **Wrap the log at 75 columns.** `COMMIT_LOG_LONG_LINE`. Trailers are exempt,
  so a long `Fixes:` or `Closes:` line is fine and must not be folded. A
  reflowed paragraph pasted back as one long line is the usual regression.
- **Quoted stack dumps are exempt** — checkpatch sets an internal
  "possible stack dump" flag on a line starting with `BUG:` or `WARNING:` and
  clears it at the **next blank line** (`scripts/checkpatch.pl`, the
  `commit_log_possible_stack_dump` block; ~line 3331 as of 7.3-rc1). So
  **deleting a quoted excerpt means re-wrapping every line in that paragraph**.
- **Imperative mood.** `submitting-patches.rst:94` is explicit: "Describe your
  changes in imperative mood, e.g. 'make xyzzy do frotz'". Drop "we can",
  "this patch", "In order to fix this issue".
- Line 2 must be blank; no diff or `---` inside the log body.

To check a message that is not yet an exported patch, splice it onto the
working-tree diff:

    { printf 'From: X <x@y>\nSubject: [PATCH] '; cat commit.txt;
      echo '---'; git diff; } > /tmp/m.patch
    (cd linux && ./scripts/checkpatch.pl --strict /tmp/m.patch)

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
- Rewriting the message invalidates the exported patch. Re-export before
  sending, and say which exported revisions are now stale.

## Worked example

The shape above, at the length above. Paragraph 1 sets up the assumption for a
stranger, the excerpt makes it checkable, paragraph 2 is the mechanism with no
reproducer trivia, paragraph 3 is the fix plus why it is not a revert.
The whole example is indented here; in the real message only the code
excerpt is, with a tab.

    nilfs2: clear folio dirty flag when copying back from the shadow map

    While garbage collection runs, nilfs2 keeps a shadow copy of the DAT
    metadata file's page cache so that it can roll the file back if GC
    fails.  The rollback has two steps: nilfs_clear_dirty_pages() drops the
    dirty state of the folios in the DAT cache, then nilfs_copy_back_pages()
    overwrites them with the saved contents.  The second step warns if it
    still finds a dirty folio, because the first step is supposed to have
    cleared every one of them:

            /* overwrite existing folio in the destination cache */
            WARN_ON(folio_test_dirty(dfolio));

    Clearing has been best-effort since commit ca76bb226bf4 ("nilfs2: do not
    force clear folio if buffer is referenced"): nilfs_clear_folio_dirty()
    leaves a folio dirty if a buffer head under it is still busy.  Reading
    metadata creates such buffers.  nilfs_mdt_read_block() submits
    read-ahead for the blocks following the one it was asked for and waits
    only for that one, so the read-ahead buffers are still locked when it
    returns.  When the block size is smaller than the page size, several
    metadata blocks share a folio, so a single folio can hold both a dirty
    block and a locked read-ahead buffer.  Such a folio survives the
    clearing step, and the copy-back warns on it.

    Use __nilfs_clear_folio_dirty() to clear the dirty flag of the
    destination folio before overwriting it, rather than making
    nilfs_clear_folio_dirty() force-clear busy buffer heads again.

    Fixes: ca76bb226bf4 ("nilfs2: do not force clear folio if buffer is referenced")
    Closes: https://lore.kernel.org/lkml/<message-id>/
    Cc: stable@vger.kernel.org
    Assisted-by: Claude Code:claude-opus-5
    Signed-off-by: Your Name <you@example.com>

## Checklist

- Subject names the change, under 75 chars, unchanged from the previous revision.
- Four paragraphs or fewer; no reproducer itinerary, no stack dump, no waypoint
  function names, nothing a reader can delete without weakening the proof.
- A stranger to the subsystem can follow paragraph 1 without looking anything up.
- The broken assumption, the code that relies on it, and the mechanism that
  breaks it are each named; the excerpt is verbatim.
- The consequence appears at least as a clause, or an existing assertion is the
  consequence and the message names the invariant it protects; a number appears
  only with its mechanism.
- The fix sentence is imperative, and its placement — or why it is not a revert
  — is justified if non-obvious.
- Any commit cited in prose is written `commit <sha12> ("subject")`.
- Every trailer is on its own line; `Signed-off-by:` is present and last;
  `Reported-by:` only if someone else reported it.
- `Fixes:` verified against the source at `<sha>^`, not from `git blame`, with
  the three conditions checked explicitly.
- Every line ≤75 columns outside trailers and a quoted `BUG:`/`WARNING:` block.
- checkpatch `--strict` run **from inside the kernel tree**, clean.
- No placeholder (`TODO`, `XXX`) survives, or the hand-off says which remain.
- The hand-off states plainly whether the patch was built, checkpatch'd, and
  reproduced — never imply verification that did not run.
