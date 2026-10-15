// Usage: node probe.mjs <dist/cli.js> <config> <servers>
// Starts `mcporter serve --stdio`, sends initialize + tools/list (+ tools/call healthy__ping if listed),
// prints the JSON-RPC results and the bridge's stderr.
import { spawn } from 'node:child_process';
const [cli, config, servers] = process.argv.slice(2);
const child = spawn(process.execPath, [cli, '--config', config, 'serve', '--stdio', '--servers', servers], {
  env: { ...process.env, MCPORTER_OAUTH_NO_BROWSER: '1', MCPORTER_OAUTH_TIMEOUT_MS: '3000' },
  stdio: ['pipe', 'pipe', 'pipe'],
});
let stderr = ''; child.stderr.on('data', (d) => (stderr += d));
let buf = ''; const waiters = new Map();
child.stdout.on('data', (d) => {
  buf += d; let i;
  while ((i = buf.indexOf('\n')) >= 0) {
    const line = buf.slice(0, i); buf = buf.slice(i + 1);
    try { const m = JSON.parse(line); waiters.get(m.id)?.(m); } catch {}
  }
});
let id = 0;
const send = (method, params) => new Promise((resolve) => {
  const m = { jsonrpc: '2.0', id: ++id, method, params }; waiters.set(m.id, resolve);
  child.stdin.write(JSON.stringify(m) + '\n');
});
const timeout = setTimeout(() => { console.log('TIMEOUT', stderr); child.kill(); process.exit(2); }, 60000);
await send('initialize', { protocolVersion: '2025-06-18', capabilities: {}, clientInfo: { name: 'probe', version: '0' } });
child.stdin.write(JSON.stringify({ jsonrpc: '2.0', method: 'notifications/initialized' }) + '\n');
const list = await send('tools/list', {});
if (list.error) console.log('tools/list -> ERROR', JSON.stringify(list.error));
else console.log('tools/list -> tools:', JSON.stringify(list.result.tools.map((t) => t.name)));
if (list.result?.tools?.some((t) => t.name === 'healthy__ping')) {
  const call = await send('tools/call', { name: 'healthy__ping', arguments: {} });
  console.log('tools/call healthy__ping ->', JSON.stringify(call.result?.content ?? call.error));
}
console.log('bridge stderr:', JSON.stringify(stderr.trim().split('\n').filter(Boolean)));
clearTimeout(timeout); child.kill(); process.exit(0);
