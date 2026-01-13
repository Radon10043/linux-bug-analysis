#!/bin/bash

WORKSPACE=$(dirname $0)/..
$WORKSPACE/syzkaller/bin/syz-symbolize \
    -kernel_obj=$WORKSPACE/linux \
    -outdir=$WORKSPACE/reproducer/symbolize \
    kernel.log > symbolize.log