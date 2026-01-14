#!/bin/bash

WORKSPACE=$(dirname $0)/..
$WORKSPACE/syzkaller/bin/syz-symbolize \
    -kernel_obj=$WORKSPACE/linux \
    -outdir=$WORKSPACE/repro/symbolize \
    repro/kernel.log > repro/symbolize.log