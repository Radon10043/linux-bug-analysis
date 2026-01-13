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
    root@localhost "cd /tmp && gcc repro.c -lpthread -static -o repro.out && chmod +x ./repro.out && ./repro.out"