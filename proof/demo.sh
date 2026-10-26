#!/usr/bin/env bash
# Reproduces the daemon transport leak with the compiled CLI.
# Usage: demo.sh <built-mcporter-checkout> <label>   (run `pnpm install && pnpm build` in the checkout first)
# Every call runs with a different CALLER_SESSION_ID, the way separate agent sessions call the same
# keep-alive server. Uses a private daemon (MCPORTER_DAEMON_DIR in a temp dir), never ~/.mcporter.
set -euo pipefail
ROOT=$(cd "$1" && pwd); LABEL=$2; CALLERS=${CALLERS:-260}
CLI="$ROOT/dist/cli.js"
[ -f "$CLI" ] || { echo "missing $CLI: build the checkout first" >&2; exit 1; }
WORK=$(mktemp -d "${TMPDIR:-/tmp}/mcporter-proof.XXXXXX")
export MCPORTER_DAEMON_DIR="$WORK/.mcporter"
mkdir -m 700 "$MCPORTER_DAEMON_DIR"
PORT=$((40000 + RANDOM % 20000))
node "$ROOT/node_modules/tsx/dist/cli.mjs" "$ROOT/tests/servers/modern/server.ts" --http "$PORT" 2>"$WORK/fixture.log" &
FIXTURE=$!
cleanup() { node "$CLI" daemon stop >/dev/null 2>&1 || true; kill "$FIXTURE" 2>/dev/null || true; rm -rf "$WORK"; }
trap cleanup EXIT
printf '{"imports":[],"mcpServers":{"fixture":{"baseUrl":"http://127.0.0.1:%s/mcp","lifecycle":"keep-alive"}}}\n' "$PORT" >"$WORK/mcporter.json"
deadline=$((SECONDS + 15))   # fixture must answer within 15 s; each probe is capped at 1 s
until curl -s --max-time 1 -o /dev/null "http://127.0.0.1:$PORT/mcp"; do
  ((SECONDS < deadline)) || { echo "fixture did not start" >&2; cat "$WORK/fixture.log" >&2; exit 1; }
  sleep 0.1
done

transports() { node "$CLI" daemon status --json | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s).servers.length))'; }
echo "### $LABEL ($(git -C "$ROOT" rev-parse --short HEAD)): $CALLERS callers, each with its own environment"
failed=0; first_failure=""
for i in $(seq 1 "$CALLERS"); do
  out=$(CALLER_SESSION_ID="caller-$i" node "$CLI" --config "$WORK/mcporter.json" call fixture.echo text="hi $i" 2>&1) && ok=1 || ok=0
  if [ "$ok" = 1 ] && grep -q "hi $i" <<<"$out"; then
    if ((i % 64 == 0 || i >= 255)) && [ "$failed" = 0 ]; then echo "caller $i -> ok   (daemon transports: $(transports))"; fi
  else
    failed=$((failed + 1)); [ -n "$first_failure" ] || first_failure=$i
    ((failed <= 2)) && echo "caller $i -> FAIL $(grep -m1 -o 'Transport capacity[^.]*\.' <<<"$out" || head -c 100 <<<"$out")"
  fi
done
if [ "$failed" -gt 0 ]; then
  echo "first failure: caller $first_failure; $failed of $CALLERS failed (daemon transports: $(transports))"
else
  echo "all $CALLERS callers ok (daemon transports: $(transports))"
fi
echo
