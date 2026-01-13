#!/bin/bash

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
    $WORKSPACE/reproducer/repro.c root@localhost:/tmp/repro.c