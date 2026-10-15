# Proof for openclaw/mcporter#447

This branch holds evidence only and is not meant to be merged. It contains a real `mcporter serve --stdio` run, before and after the fix:

- **`proof/serve-before-after.png`:** screenshot of the run, rendered from `proof/run.log`.
- **`proof/run.log`:** raw output for three bridges on `main` (627965f) and on the fix branch (d7c4ad6):
  - healthy only;
  - one failing server plus one healthy server;
  - failing only.
- **`proof/mcporter.json`, `proof/healthy-server.mjs`, `proof/needs-auth-server.mjs` and `proof/probe.mjs`:** the fixtures and the client used to produce the log.

To reproduce:

1. Build each tree with `tsc -p tsconfig.build.json`.
2. Run `node proof/needs-auth-server.mjs 47811`.
3. Run `HOME=<empty dir> node proof/probe.mjs <tree>/dist/cli.js proof/mcporter.json needs-auth,healthy`.
