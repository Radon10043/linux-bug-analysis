# workspace for linux bug analysis

download linux and syzkaller first:
```bash
git clone https://github.com/torvalds/linux
git clone https://github.com/google/syzkaller
```

set max size of ccache:
```bash
ccache -M 50G
```

# how to print debug message with low cost

use `trace_printk` (same usage as `printk`), e.g.:
```c
trace_printk("ptr=%p\n", ptr);
```

remeber to add `ftrace_dump_on_oops` to qemu command, debug info will be printed after kernel crash:
```bash
qemu-system-x86_64 \
    ...
    -append "root=/dev/sda console=ttyS0 ftrace_dump_on_oops"
```