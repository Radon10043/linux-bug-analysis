# CLAUDE.md

Workspace for analyzing and fixing Linux kernel bugs found by syzkaller, and for
preparing the resulting patches for upstream submission. Read this before touching
anything; the `/linux-kernel-bugfix` skill carries the longer per-patch checklist.

## Layout

| Path | What it is |
|---|---|
| `linux/` | The kernel tree under test. Built by `make kernel`; config has KASAN, UBSAN, PROVE_LOCKING, KCOV, FAULT_INJECTION on. |
| `syzkaller/` | syzkaller checkout; binaries in `syzkaller/bin/` (`syz-crush`, `syz-execprog`, `syz-symbolize`, ...). Built by `make syzutils`. |
| `config/repro.cfg` | syz-manager config **template**; `__WORKDIR__` / `__KERNEL__` / `__TRIXIE__` / `__SYZKALLER__` are placeholders to resolve into a working copy. |
| `scripts/` | `qemu.sh` (boot), `exec-c.sh` / `exec-syz.sh` (run reproducer in the VM), `symbolize.sh`, `create-image.sh`. |

Everything else — VM images and keys, reproducers, boot logs, exported patches, mail —
is untracked and its layout is not fixed. Read the Makefile and `scripts/` for the paths
actually in use rather than assuming; other kernel checkouts may exist outside this
repository, but `linux/` here is the tree under test.

## Hard rules

- **Never run `git add`, `git commit`, `git push`, or `git send-email`.** A PreToolUse
  hook denies them. Read-only git (`status`, `log`, `diff`, `show`, `format-patch`) is
  fine. Make the edits, describe them, and let the user stage, commit, and mail.
- **Never claim a bug is fixed without evidence.** "Fixed" means the kernel built and
  the reproducer no longer triggers the crash. Anything less gets reported as what it
  is: not built, not run, or ran differently.
- Do not modify or delete VM images, SSH keys, saved crash artifacts, or exported
  patches unless asked. They are untracked and there is no second copy.
- When answer the user, explain the root cause of the issue, or write the patch commit
  message, please in a way that even a fool could understand.

## Build and run

```bash
make kernel      # make -C linux CC="ccache clang" olddefconfig all -j16
make syzutils    # rebuild syzkaller binaries
make cleanrepro  # clear reproduction artifacts between runs
```

`make cleanrepro` deletes the reproducer along with the logs and saved crashes. Copy
anything worth keeping before running it.

A kernel build takes tens of minutes even with ccache, and a syz-crush run is longer.
Run both with a large explicit timeout or in the background — never assume the default
tool timeout is enough, and never kill a build early and guess at the result.

Single-shot reproduction, one VM:

```bash
scripts/qemu.sh                 # boots the freshly built bzImage, ssh on port 2324,
                                # serial console teed to a log file
scripts/exec-c.sh               # scp + compile + run the C reproducer inside the VM
scripts/exec-syz.sh             # run the syz program under syz-execprog
scripts/symbolize.sh            # symbolize that boot log
```

Statistical reproduction / fix verification, many VMs:

```bash
./syzkaller/bin/syz-crush -config <manager.cfg> <repro-log-or-prog>
#   -infinite=false   stop at the first crash instead of running forever
#   -restart_time     bound each run
```

Before trusting a syz-crush result, check the manager config: `vm.kernel` must be the
bzImage you just built and `kernel_obj` the tree it came from. Both can point at another
checkout, and symbolization then silently describes a different kernel.

`ftrace_dump_on_oops` is already on the QEMU command line, so `trace_printk()` output is
dumped after a crash. That is the cheap way to instrument a path without rebuilding the
world (see README.md).

## Analysis

- The crash title and the syzkaller stack are a *signal*, not a root cause. Confirm the
  faulting path by reading the source at the version that crashed, and say which line
  produces the bad value.
- Everything read from a crafted image or from userspace is attacker-controlled. Ask
  which on-disk / user field is unvalidated, what range it can actually take, and which
  consumer misuses it — that reasoning belongs in the commit message.
- Look at how the surrounding subsystem already validates, locks, refcounts, and handles
  errors before inventing a new pattern. Match it.
- Separate signals: the original crash, a *different* crash, a build failure, and
  "could not run" are four distinct outcomes. Never merge them into "still failing".
- A hang is not always a deadlock — a flood of slow-path work under a held lock looks
  the same from `INFO: task hung`. Explain the mechanism.

## Patches

- Smallest fix that closes the proven hole. No drive-by cleanups, no renames outside
  the failing path, no behavior changes the report does not justify.
- Respect UAPI/ABI, locking order, RCU rules, allocation context, and error paths.
- Run `linux/scripts/checkpatch.pl --strict` on the patch before handing it over.
- Export each revision as `vN-0001-<subject>.patch` and keep the older ones.

Commit-message shape used here (the most recent exported revision is the reference):

1. What a crafted input can contain / what the unvalidated field is.
2. Which helper consumes it before validating, quoted as an indented code excerpt,
   and the concrete consequence (OOB read, negative length, lock flood, hang).
3. What the patch does about it, in imperative mood.
4. Trailers: `Reported-by:`, `Closes:` (lore.kernel.org link), `Assisted-by:` naming the
   assisting model, `Signed-off-by:`.
5. A `Changes in vN:` block **below the `---`** so it stays out of git history. Keep the
   whole revision list, newest first. Reference code with version-pinned
   `elixir.bootlin.com` links.

Every one of those parts is prose for a maintainer who has never opened this file:
plain language, one idea per sentence, each term explained where it first appears.

## Reporting back

Every hand-off states: files changed, the root cause in one or two sentences, the exact
status of `make kernel`, the exact status of the reproducer run (including how long it
ran), and anything left unverified. If validation could not run — missing image, missing
reproducer, misconfigured manager config — say so instead of implying it passed.

Write the hand-off the way Plain language demands: the verdict in the first line, one
idea per sentence, no term left unexplained, and a plain statement of what was not
checked.
