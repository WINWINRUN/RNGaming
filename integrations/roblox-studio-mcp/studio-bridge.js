#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const { spawn } = require("child_process");

const DEFAULT_PROTOCOL_VERSION = "2024-11-05";
const DEFAULT_SERVER_PATH = process.env.RBX_MCP_SERVER
  || path.join(__dirname, "rbx-studio-mcp.exe");
const DEBUG = process.env.RBX_MCP_DEBUG === "1";

class McpSession {
  constructor(serverPath) {
    this.serverPath = serverPath;
    this.child = null;
    this.buffer = "";
    this.nextId = 1;
    this.pending = new Map();
    this.stderr = "";
    this.exited = false;
  }

  async start() {
    if (!fs.existsSync(this.serverPath)) {
      throw new Error(
        `MCP server executable not found at "${this.serverPath}". `
        + "Set RBX_MCP_SERVER or place rbx-studio-mcp.exe next to this script."
      );
    }

    this.child = spawn(this.serverPath, ["--stdio"], {
      stdio: ["pipe", "pipe", "pipe"],
    });

    this.child.stdout.on("data", (chunk) => {
      this.buffer += chunk.toString("utf8");
      this.#drainStdout();
    });

    this.child.stderr.on("data", (chunk) => {
      const text = chunk.toString("utf8");
      this.stderr += text;
      if (DEBUG) {
        process.stderr.write(text);
      }
    });

    this.child.on("exit", (code, signal) => {
      this.exited = true;
      const reason = signal ? `signal ${signal}` : `code ${code}`;
      for (const { reject } of this.pending.values()) {
        reject(new Error(`MCP server exited with ${reason}${this.stderr ? `\n${this.stderr.trim()}` : ""}`));
      }
      this.pending.clear();
    });

    await this.request("initialize", {
      protocolVersion: DEFAULT_PROTOCOL_VERSION,
      capabilities: {},
      clientInfo: {
        name: "studio-bridge",
        version: "0.1.0",
      },
    });

    this.notify("notifications/initialized", {});
  }

  notify(method, params) {
    this.#send({ jsonrpc: "2.0", method, params });
  }

  request(method, params) {
    if (this.exited) {
      return Promise.reject(new Error("MCP server is not running."));
    }

    const id = this.nextId++;
    this.#send({ jsonrpc: "2.0", id, method, params });

    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
    });
  }

  async listTools() {
    const response = await this.request("tools/list", {});
    return response.result?.tools || [];
  }

  async waitForTools({ attempts = 10, delayMs = 1000 } = {}) {
    let tools = [];

    for (let index = 0; index < attempts; index += 1) {
      tools = await this.listTools();
      if (tools.length > 0) {
        return tools;
      }

      if (index < attempts - 1) {
        await sleep(delayMs);
      }
    }

    return tools;
  }

  async callTool(name, args) {
    const response = await this.request("tools/call", {
      name,
      arguments: args,
    });

    if (response.result?.isError) {
      const text = extractText(response);
      throw new Error(text || `Tool "${name}" returned an error.`);
    }

    return response;
  }

  async close() {
    if (!this.child || this.exited) {
      return;
    }

    this.child.kill();
    await sleep(150);
  }

  #send(message) {
    if (!this.child || !this.child.stdin.writable) {
      throw new Error("MCP server stdin is not writable.");
    }

    this.child.stdin.write(`${JSON.stringify(message)}\n`);
  }

  #drainStdout() {
    while (true) {
      const newlineIndex = this.buffer.indexOf("\n");
      if (newlineIndex === -1) {
        return;
      }

      const line = this.buffer.slice(0, newlineIndex).trim();
      this.buffer = this.buffer.slice(newlineIndex + 1);

      if (!line) {
        continue;
      }

      let message;
      try {
        message = JSON.parse(line);
      } catch (error) {
        if (DEBUG) {
          process.stderr.write(`Failed to parse MCP response: ${line}\n`);
        }
        continue;
      }

      if (typeof message.id !== "undefined" && this.pending.has(message.id)) {
        const { resolve, reject } = this.pending.get(message.id);
        this.pending.delete(message.id);

        if (message.error) {
          reject(new Error(message.error.message || JSON.stringify(message.error)));
        } else {
          resolve(message);
        }
      }
    }
  }
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function extractText(response) {
  const parts = response?.result?.content || [];
  return parts
    .filter((item) => item && item.type === "text" && typeof item.text === "string")
    .map((item) => item.text)
    .join("");
}

function printHelp() {
  console.log(`Roblox Studio bridge

Usage:
  node studio-bridge.js tools [--json]
  node studio-bridge.js mode [--json]
  node studio-bridge.js console [--json]
  node studio-bridge.js play <start_play|stop|run_server> [--json]
  node studio-bridge.js insert-model <query...> [--json]
  node studio-bridge.js run-code <luau...> [--json]
  node studio-bridge.js run-code-file <path> [--json]
  node studio-bridge.js call <tool-name> [json-args] [--json]

Notes:
  - Open a real place in Roblox Studio before calling tools. The Studio start page alone
    does not fully load the user plugin bridge.
  - Override the MCP server path with RBX_MCP_SERVER if needed.
  - Use RBX_MCP_DEBUG=1 to forward server stderr logs.
`);
}

function parseArgs(argv) {
  const args = [...argv];
  const jsonIndex = args.indexOf("--json");
  const asJson = jsonIndex !== -1;
  if (asJson) {
    args.splice(jsonIndex, 1);
  }

  const command = args.shift() || "help";
  return { command, args, asJson };
}

function formatToolList(tools) {
  return tools
    .map((tool) => {
      const firstLine = (tool.description || "").split("\n")[0].trim();
      return firstLine ? `${tool.name} - ${firstLine}` : tool.name;
    })
    .join("\n");
}

async function run() {
  const { command, args, asJson } = parseArgs(process.argv.slice(2));
  if (command === "help" || command === "--help" || command === "-h") {
    printHelp();
    return;
  }

  const session = new McpSession(DEFAULT_SERVER_PATH);

  try {
    await session.start();

    let output;

    if (command === "tools") {
      const tools = await session.waitForTools();
      if (tools.length === 0) {
        throw new Error(
          "No Studio tools are available yet. Open a place in Roblox Studio and wait for "
          + "\"The MCP Studio plugin is ready for prompts.\" in the Studio output."
        );
      }
      output = { tools };
      if (asJson) {
        console.log(JSON.stringify(output, null, 2));
      } else {
        console.log(formatToolList(tools));
      }
      return;
    }

    const tools = await session.waitForTools();
    if (tools.length === 0) {
      throw new Error(
        "Roblox Studio is reachable, but no tools are exposed yet. Open a real place in Studio "
        + "and let the MCP plugin finish loading."
      );
    }

    switch (command) {
      case "mode":
        output = await session.callTool("get_studio_mode", {});
        break;
      case "console":
        output = await session.callTool("get_console_output", {});
        break;
      case "play":
        if (args.length !== 1) {
          throw new Error("play expects exactly one mode: start_play, stop, or run_server.");
        }
        output = await session.callTool("start_stop_play", { mode: args[0] });
        break;
      case "insert-model":
        if (args.length === 0) {
          throw new Error("insert-model expects a search query.");
        }
        output = await session.callTool("insert_model", { query: args.join(" ") });
        break;
      case "run-code":
        if (args.length === 0) {
          throw new Error("run-code expects Luau source.");
        }
        output = await session.callTool("run_code", { command: args.join(" ") });
        break;
      case "run-code-file": {
        if (args.length !== 1) {
          throw new Error("run-code-file expects exactly one path.");
        }
        const filePath = path.resolve(process.cwd(), args[0]);
        const commandText = fs.readFileSync(filePath, "utf8");
        output = await session.callTool("run_code", { command: commandText });
        break;
      }
      case "call": {
        if (args.length < 1 || args.length > 2) {
          throw new Error("call expects a tool name and optional JSON args.");
        }
        const toolName = args[0];
        const toolArgs = args[1] ? JSON.parse(args[1]) : {};
        output = await session.callTool(toolName, toolArgs);
        break;
      }
      default:
        throw new Error(`Unknown command "${command}". Use "help" to see supported commands.`);
    }

    if (asJson) {
      console.log(JSON.stringify(output, null, 2));
      return;
    }

    const text = extractText(output);
    if (text) {
      process.stdout.write(text.endsWith("\n") ? text : `${text}\n`);
    } else {
      console.log(JSON.stringify(output.result ?? output, null, 2));
    }
  } finally {
    await session.close();
  }
}

run().catch((error) => {
  process.stderr.write(`${error.message}\n`);
  process.exitCode = 1;
});
