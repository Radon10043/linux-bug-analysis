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
    $WORKSPACE/repro/repro.c root@localhost:/tmp/repro.c

ssh -p 2324 \
    -F /dev/null \
    -o UserKnownHostsFile=/dev/null \
    -o IdentitiesOnly=yes \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=no \
    -o ConnectTimeout=10 \
    -i $WORKSPACE/Debian/bullseye/bullseye.id_rsa \
    root@localhost "cd /tmp && gcc repro.c -lpthread -static -o repro.out && chmod +x ./repro.out && ./repro.out"