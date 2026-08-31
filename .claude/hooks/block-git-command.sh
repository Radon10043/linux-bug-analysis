#!/usr/bin/env bash
# PreToolUse/Bash guard: refuse git subcommands that stage, record, publish, or
# mail patches. Reads the hook payload on stdin, prints a deny decision on match.
#
# Usage: block-git-command.sh <subcommand-regex> [human-readable-label]
#   e.g. block-git-command.sh 'push'       'git push'
#        block-git-command.sh 'send-email' 'git send-email'
set -uo pipefail

sub_re="${1:?usage: block-git-command.sh <subcommand-regex> [label]}"
label="${2:-git ${sub_re}}"

payload="$(cat)"
if command -v jq >/dev/null 2>&1; then
  cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null)"
else
  # No jq: scan the raw JSON. Command text appears verbatim inside the string.
  cmd="$payload"
fi
[ -n "$cmd" ] || exit 0

# Split on shell separators so `make foo && git push` is inspected per segment,
# then match `git`, any number of intervening tokens (-C dir, --git-dir=..., -c k=v),
# and the subcommand as a standalone token.
if printf '%s' "$cmd" | tr ';&|' '\n\n\n' |
   grep -Eqi "(^|[[:space:]])git[[:space:]]+([^[:space:]]+[[:space:]]+)*${sub_re}([[:space:]]|$)"; then
  jq -n --arg label "$label" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: ("`" + $label + "` is blocked in this repository. Staging, committing, pushing, and mailing patches are the user'"'"'s job — report the change and let them run it.")
    },
    systemMessage: ("Blocked " + $label + " (project hook)")
  }'
  exit 0
fi
exit 0
