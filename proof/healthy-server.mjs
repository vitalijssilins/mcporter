import { McpServer } from '<repo>/node_modules/@modelcontextprotocol/sdk/dist/esm/server/mcp.js';
import { StdioServerTransport } from '<repo>/node_modules/@modelcontextprotocol/sdk/dist/esm/server/stdio.js';
const server = new McpServer({ name: 'healthy', version: '1.0.0' });
server.tool('ping', 'Reply with pong', async () => ({ content: [{ type: 'text', text: 'pong' }] }));
await server.connect(new StdioServerTransport());
