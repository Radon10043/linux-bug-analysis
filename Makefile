COMPILER=ccache clang-19

kernel:
	$(MAKE) -C linux CC="$(COMPILER)" olddefconfig all -j8

syzutils:
	$(MAKE) -C syzkaller execprog executor symbolize -j8

clean:
	rm *.log