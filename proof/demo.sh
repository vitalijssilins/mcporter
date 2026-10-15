#!/usr/bin/env bash
# Live demo for openclaw/mcporter#447 — every command below really runs.
set -u
cd "$(dirname "$0")"
export HOME="$PWD/home" PS4="" GIT_PAGER=cat PAGER=cat TERM=xterm-256color
U=../mcporter-upstream
say() { printf '\n\033[1;36m# %s\033[0m\n' "$*"; sleep 1.2; }
run() { printf '\033[1;32m$\033[0m %s\n' "$*"; sleep 0.6; eval "$@"; sleep 1.5; }
say "two keep-alive servers: 'healthy' (stdio, tool ping) and 'needs-auth' (HTTP, always 401)"
run "cat mcporter.json | sed 's#$PWD#.#'"
node needs-auth-server.mjs 47811 & SRV=$!
sleep 1
say "BEFORE: openclaw/mcporter main"
run "git -C $U/main-build log --oneline -1"
run "node probe.mjs $U/main-build/dist/cli.js \$PWD/mcporter.json needs-auth,healthy"
node $U/main-build/dist/cli.js --config "$PWD/mcporter.json" daemon stop >/dev/null 2>&1
say "AFTER: fix/serve-isolate-list-failures"
run "git -C $U/repo log --oneline -1 d7c4ad6"
run "node probe.mjs $U/repo/dist/cli.js \$PWD/mcporter.json needs-auth,healthy"
say "AFTER, every server failing: tools/list still errors"
run "node probe.mjs $U/repo/dist/cli.js \$PWD/mcporter.json needs-auth"
node $U/repo/dist/cli.js --config "$PWD/mcporter.json" daemon stop >/dev/null 2>&1
kill $SRV
say "done"
