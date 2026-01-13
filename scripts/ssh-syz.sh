#!/bin/bash
WORKSPACE=$(dirname $0)/..
ssh -p 2324 \
    -F /dev/null \
    -o UserKnownHostsFile=/dev/null \
    -o IdentitiesOnly=yes \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=no \
    -o ConnectTimeout=10 \
    -i $WORKSPACE/Debian/bullseye/bullseye.id_rsa \
    root@localhost "cd /tmp && ./syz-execprog -enable=all -repeat=0 -procs=8 ./repro.syz"