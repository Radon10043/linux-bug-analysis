#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'USAGE'
Usage: verify_kernel_fix.sh [syz-crush-args...]

Run from the Linux kernel bug-analysis repository root after applying a patch.
The script runs:
  1. make kernel
  2. ./syzkaller/bin/syz-crush [syz-crush-args...]

Logs are written under ${TMPDIR:-/tmp}/linux-kernel-bugfix-logs by default.
Set LOG_DIR to override the log root.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

repo_root="$(pwd)"
syz_crush="./syzkaller/bin/syz-crush"
log_root="${LOG_DIR:-${TMPDIR:-/tmp}/linux-kernel-bugfix-logs}"
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
log_dir="${log_root}/${stamp}"
build_log="${log_dir}/make-kernel.log"
crush_log="${log_dir}/syz-crush.log"

mkdir -p "${log_dir}"

printf 'Repository: %s\n' "${repo_root}"
printf 'Log directory: %s\n' "${log_dir}"

if [[ ! -e "Makefile" ]]; then
  printf 'error: no Makefile found in %s; run this from the repository root\n' "${repo_root}" >&2
  exit 2
fi

if [[ ! -x "${syz_crush}" ]]; then
  printf 'error: %s is missing or not executable\n' "${syz_crush}" >&2
  exit 2
fi

printf '\n==> Building kernel: make kernel\n'
if ! make kernel 2>&1 | tee "${build_log}"; then
  printf '\nmake kernel failed; see %s\n' "${build_log}" >&2
  exit 1
fi

printf '\n==> Running syz-crush: %s' "${syz_crush}"
for arg in "$@"; do
  printf ' %q' "${arg}"
done
printf '\n'

if ! "${syz_crush}" "$@" 2>&1 | tee "${crush_log}"; then
  printf '\nsyz-crush failed or reproduced a crash; see %s\n' "${crush_log}" >&2
  exit 1
fi

printf '\nValidation completed successfully.\n'
printf 'Build log: %s\n' "${build_log}"
printf 'syz-crush log: %s\n' "${crush_log}"
