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