// Minimal MCP-over-HTTP endpoint that rejects every request with 401, like a server whose OAuth grant is missing.
import http from 'node:http';
const port = Number(process.argv[2] || 47811);
http.createServer((req, res) => {
  res.writeHead(401, { 'WWW-Authenticate': `Bearer resource_metadata="http://127.0.0.1:${port}/.well-known/oauth-protected-resource"`, 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error: 'unauthorized' }));
}).listen(port, '127.0.0.1');
