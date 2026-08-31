CC=ccache clang

syzutils:
	$(MAKE) -C syzkaller generate execprog executor symbolize crush -j8

kernel:
	$(MAKE) -C linux CC="$(CC)" olddefconfig all -j16

cleanrepro:
	rm -rf repro/symbolize repro/*.log repro/report repro/repro.c repro/repro.syz repro/crashes
