#!/bin/sh
# SignalAI plugin update check — runs on SessionStart in Claude Code.
#
# Compares the locally-installed plugin rev (.plugin-rev) against the latest
# published rev from the backend oracle. If behind, emits a one-line nudge via
# the SessionStart additionalContext channel so Claude can mention it if the
# user does anything SignalAI-related this session.
#
# HARD RULES: never block the session, never error, never nag more than once
# per 24h. Any failure (offline, timeout, missing files) exits 0 silently.

set -u

ORACLE_URL="https://35.94.249.241.sslip.io/api/v1/plugin/version"
THROTTLE_FILE="${TMPDIR:-/tmp}/signalai-plugin-update-check"
LOCAL_REV_FILE="${CLAUDE_PLUGIN_ROOT:-.}/.plugin-rev"

# 1. Self-throttle: skip if checked within the last 24h (86400s).
# Store the epoch INSIDE the file (portable) — `date -r FILE` / `stat` flags
# differ between BSD/macOS and GNU/Linux, so never rely on file mtime here.
if [ -f "$THROTTLE_FILE" ]; then
  last=$(cat "$THROTTLE_FILE" 2>/dev/null || echo 0)
  case "$last" in *[!0-9]*|'') last=0 ;; esac
  now=$(date +%s)
  if [ $((now - last)) -lt 86400 ]; then
    exit 0
  fi
fi

# 2. Read local rev.
[ -f "$LOCAL_REV_FILE" ] || exit 0
local_rev=$(tr -d '[:space:]' < "$LOCAL_REV_FILE")
[ -n "$local_rev" ] || exit 0

# 3. Fetch the oracle (2s budget). Any failure → throttle + silent exit.
body=$(curl -fsS --max-time 2 "$ORACLE_URL" 2>/dev/null) || { date +%s > "$THROTTLE_FILE"; exit 0; }

# Extract latest_rev + min_supported_rev with grep/sed (no jq dependency).
latest_rev=$(printf '%s' "$body" | sed -n 's/.*"latest_rev"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
min_rev=$(printf '%s' "$body" | sed -n 's/.*"min_supported_rev"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

date +%s > "$THROTTLE_FILE"

# 4. No usable latest → treat as current, silent.
[ -n "$latest_rev" ] || exit 0

# 5. Up to date (string compare works: revs are zero-padded YYYYMMDDHHMM).
[ "$local_rev" \< "$latest_rev" ] || exit 0

# 6. Behind → nudge. If below the hard floor, mark it required.
update_cmd="/plugin marketplace update signalai && /reload-plugins"
if [ -n "$min_rev" ] && [ "$local_rev" \< "$min_rev" ]; then
  msg="The installed SignalAI plugin (rev $local_rev) is below the minimum supported rev ($min_rev) and may stop working. Tell the user to update now: run \\\`$update_cmd\\\`."
else
  msg="A newer SignalAI plugin is available (local $local_rev, latest $latest_rev). If the user does anything SignalAI-related this session, mention once that they can update with \\\`$update_cmd\\\`."
fi

printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$msg"
exit 0
