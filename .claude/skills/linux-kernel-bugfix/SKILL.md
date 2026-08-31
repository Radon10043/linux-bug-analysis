---
name: linux-kernel-bugfix
description: Diagnose, patch, build, and validate Linux kernel bugs, especially syzkaller/syzbot reports, crash reproducers, kernel splats, KASAN/KCSAN/KMSAN/UBSAN reports, lockdep warnings, use-after-free bugs, NULL dereferences, races, and regressions. Use when asked to fix a Linux kernel issue and every proposed patch must be verified from the working directory with `make kernel` followed by `./syzkaller/bin/syz-crush`.
---

# Linux Kernel Bugfix

## Overview

Use this skill to keep Linux kernel bug fixes narrow, evidence-driven, and verified. After every patch, build from the target repository working directory with `make kernel`, then run `./syzkaller/bin/syz-crush` to check whether the reported bug still reproduces.

## Workflow

1. Preserve the bug signal before editing:
   - Identify the crash title, report type, faulting subsystem, stack trace, reproducer, and relevant config or syzkaller artifacts.
   - Search the touched subsystem for existing locking, lifetime, refcount, bounds-checking, and error-path patterns before inventing a new pattern.
   - Treat syzkaller output as a reproducer signal, not proof of root cause. Confirm the failing path in source.

2. Patch conservatively:
   - Prefer the smallest fix that addresses the proven lifetime, concurrency, validation, or error-handling bug.
   - Follow nearby kernel style and helper APIs. Avoid broad refactors, unrelated cleanups, and behavior changes outside the failing path.
   - Keep ABI, UAPI, locking order, RCU rules, reference ownership, and memory allocation context in mind.

3. Validate every patch from the repository working directory:

   ```bash
   make kernel
   ./syzkaller/bin/syz-crush
   ```

   If the syzkaller task requires arguments, pass the task-specific arguments to `syz-crush` (this repo keeps a syz-crush manager config at `config/repro.cfg`, e.g. `./syzkaller/bin/syz-crush -config config/repro.cfg <repro-log>`). Do not claim the bug is fixed unless the kernel build succeeds and `syz-crush` no longer reproduces the target crash.

   Kernel builds and crash reproduction are long-running; run them with a generous `timeout` (or in the background) instead of assuming the default tool timeout is enough.

4. Interpret verification strictly:
   - If `make kernel` fails, fix the compile error before running crash validation.
   - If `syz-crush` still reports the same crash, revisit the root cause and adjust the patch.
   - If `syz-crush` reports a different crash, separate that signal from the original fix and state the distinction.
   - If validation cannot run because required binaries, reproducers, or configs are missing, report that limitation explicitly.

5. Report the result with the files changed, the root-cause reasoning, and the exact validation outcome. Include the command status for `make kernel` and `./syzkaller/bin/syz-crush`.

## Validation Helper

Use the bundled helper when a single repeatable command is preferable:

```bash
bash .claude/skills/linux-kernel-bugfix/scripts/verify_kernel_fix.sh
```

Run it from the target repository root. Pass any required `syz-crush` arguments after the script name:

```bash
bash .claude/skills/linux-kernel-bugfix/scripts/verify_kernel_fix.sh <syz-crush-args>
```

The helper runs `make kernel`, then `./syzkaller/bin/syz-crush "$@"`, writes logs under `${TMPDIR:-/tmp}/linux-kernel-bugfix-logs`, and exits nonzero on the first failed phase.

## Kernel Fix Checklist

Before finishing, ensure:

- The patch directly addresses the observed failing path.
- The change follows subsystem conventions and does not widen locking or lifetime assumptions without justification.
- `make kernel` was run after the final patch.
- `./syzkaller/bin/syz-crush` was run after the successful build.
- Remaining failures are clearly identified as compile failures, the original crash, a different crash, or missing validation prerequisites.
