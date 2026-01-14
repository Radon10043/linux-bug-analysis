#!/bin/bash

set -e

WORKSPACE=$(dirname $0)/..

scp -P 2324 \
    -F /dev/null \
    -o UserKnownHostsFile=/dev/null \
    -o IdentitiesOnly=yes \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=no \
    -o ConnectTimeout=10 \
    -i $WORKSPACE/Debian/bullseye/bullseye.id_rsa \
    -v \
    $WORKSPACE/syzkaller/bin/linux_amd64/* root@localhost:/tmp/

scp -P 2324 \
    -F /dev/null \
    -o UserKnownHostsFile=/dev/null \
    -o IdentitiesOnly=yes \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=no \
    -o ConnectTimeout=10 \
    -i $WORKSPACE/Debian/bullseye/bullseye.id_rsa \
    -v \
    $WORKSPACE/repro/repro.syz root@localhost:/tmp/repro.syz

ssh -p 2324 \
    -F /dev/null \
    -o UserKnownHostsFile=/dev/null \
    -o IdentitiesOnly=yes \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=no \
    -o ConnectTimeout=10 \
    -i $WORKSPACE/Debian/bullseye/bullseye.id_rsa \
    root@localhost "cd /tmp && ./syz-execprog -enable=all -repeat=0 -procs=8 ./repro.syz"