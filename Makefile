COMPILER=ccache clang

syzutils:
	$(MAKE) -C syzkaller execprog executor symbolize -j8

kernel:
	$(MAKE) -C linux CC="$(COMPILER)" olddefconfig all -j8

cleanrepro:
	rm -rf repro/symbolize repro/*.log repro/report repro/repro.c repro/repro.syz