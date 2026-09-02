---
name: kernel-bug-report-email
description: Write or review the mail that reports a Linux kernel bug to a subsystem's maintainers and list before any patch is sent — recipients from MAINTAINERS, the crash excerpt, a root-cause analysis aimed at someone who does not know the subsystem, the proposed diff, and the reproducer artifacts. Use when drafting or auditing such a report, or when capturing its lore Message-ID for the patch's Closes: tag.
---

# Kernel Bug Report Email

## Overview

Companion to `linux-kernel-bugfix` (diagnosis, build, validation) and
`kernel-commit-message` (the patch's own log). This one is the mail sent to
the maintainers and the list *before* the patch, so that its lore Message-ID
can become the patch's `Closes:` tag.

The report and the commit message describe the same bug to two different
readers. The commit message has to prove the analysis was **measured** — field
values, block numbers, state dumps. The report has to be **understood on first
read by someone who has never touched the subsystem**. Text that serves one
usually fails the other, so write the analysis fresh instead of pasting the
commit log in.

## Writing the root cause

Order it **symptom → cause → impact**, roughly a paragraph each:

1. **What the report literally says**, restated as a state — "the WARNING
   triggers because a folio of the DAT metadata file is still dirty where
   `nilfs_copy_back_pages()` expects a clean one" — then the least context
   needed to explain why that code runs at all.
2. **Why that state arises.** The regressing commit if there is one, then the
   concrete mechanism, carrying every condition it depends on.
3. **What it costs.** The state left behind, plus the crash under
   `panic_on_warn` when the WARNING is the whole bug.

Chronological order — untrusted input, call path, symptom — is the *commit
message's* shape and reads badly here: it makes the reader hold a subsystem
they do not know in their head until the final sentence. Ask for the plain
reading every time; the version written for a stranger has consistently come
out better than the version written for the maintainer.

**Name only the functions that carry a step of the story.** One nilfs2 report
came down to four: where the WARN sits, what skipped the clearing, what left
the buffer busy, what reset the buffer state afterwards. Every other
identifier (`nilfs_palloc_freev()`, `nilfs_clean_segments()`, `-ENOENT`,
`nilfs_lookup_dirty_data_buffers()`) was cut for a plain-English clause and
nothing was lost.

**Leave the reproducer's numbers in the commit message.** "A virtual block
number the DAT file does not map" is the report's version; `vblocknr 65537`,
group 8, DAT block 2057 and the `b_state` values belong in the log, where
their job is to prove the analysis was not imagined.

## Compressing without breaking the claim

Every pass that shortens the analysis can quietly falsify it. All three of
these survived a rewrite and had to be caught on re-review:

- **A dropped condition widens the claim.** "A locked read-ahead buffer may
  share a folio with a dirty block" became false once "when the block size is
  smaller than the page size" was cut — with one block per folio it cannot
  happen at all. `may` does not rescue an impossible claim.
- **Reordering reverses the mechanism.** "`nilfs_copy_folio()` then clears
  BH_Dirty ... and a warning will be printed" put the WARN after the copy; in
  the source it comes before. Re-read the function after every rewrite.
- **Elliptical transitions stop parsing.** "One is." / "One can be." as a
  standalone sentence answering the previous paragraph is opaque to most
  readers, and worse across a paragraph break. Use a complete causal
  sentence: "That can happen because ...".

## Mechanics that break during hand-editing

The analysis will go several rounds with the author. What breaks in between:

- **The diff loses its tabs.** Editors and paste buffers turn them into
  spaces and the hunk stops applying. Regenerate it from `git diff` instead
  of retyping, and verify with `cat -A` — leading `^I`, never spaces.
- **The diff drifts from the tree.** When the patch changes after the mail is
  drafted the two silently disagree; diff the mail's hunk against `git diff`
  output before sending.
- **Connectives get deleted.** Removing a "so" or a "because" leaves two
  independent clauses joined by a comma.
- **Person drifts.** A hand-added sentence says "on my machine" in a mail
  that says "we" everywhere else.
- **Sentence spacing.** Two spaces after a full stop, throughout.

## After sending

Capture the lore.kernel.org Message-ID of your own mail and put it in the
patch's `Closes:` tag. Send the patch as a **new top-level thread**, not as a
reply to the report — replying buries it and leaves CI testing nothing.

## Checklist

- Recipients copied from the current MAINTAINERS entry, not from memory.
- Subject is the crash title and will not change across patch revisions.
- The named commit and the report's version string agree, with no unexplained
  `-NNNNN-g<sha>` suffix.
- Non-subsystem frames in the report were spot-checked against that tree.
- One clause says how the bug is triggered and what privilege it needs.
- Root cause runs symptom → cause → impact and names the field, the helper,
  the failing state and the consequence. As short as the mechanism allows,
  not shorter.
- Every function name in the analysis carries a step of the story; the
  reproducer's numbers stayed in the commit message.
- No ``` fences, no body `---`, diff indented with tabs.
- The mail's diff is byte-identical to `git diff` on the working tree.
- Person is consistent from greeting to closing line.
- LLM assistance is disclosed.
- No invented link; placeholders are called out at hand-off.
- Nothing claims a build, a checkpatch run, or a reproduction that did not
  actually happen.
