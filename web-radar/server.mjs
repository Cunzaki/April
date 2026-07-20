import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import { execSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PUBLIC = path.join(__dirname, "public");
const BASE_PORT = Number(process.env.APRIL_WEB_RADAR_PORT || 8765);
const HOST = process.env.APRIL_WEB_RADAR_HOST || "0.0.0.0";
let PORT = BASE_PORT;

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon",
  ".png": "image/png",
};

const radarCache = {
  raw: null,
  mtimeMs: 0,
  seq: -1,
};

function radarFilePath() {
  const local = process.env.LOCALAPPDATA;
  if (local) {
    return path.join(local, "Project Vector", "Scripts", "April_web_radar.json");
  }
  const home = process.env.HOME || process.env.USERPROFILE || process.cwd();
  return path.join(home, "April_web_radar.json");
}

function localAddresses() {
  const addrs = [`http://127.0.0.1:${PORT}`, `http://localhost:${PORT}`];
  const nets = os.networkInterfaces();
  for (const list of Object.values(nets)) {
    for (const net of list || []) {
      if (net.family === "IPv4" && !net.internal) {
        addrs.push(`http://${net.address}:${PORT}`);
      }
    }
  }
  return [...new Set(addrs)];
}

function sendJson(res, status, body) {
  res.writeHead(status, {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store, no-cache, must-revalidate",
    "Access-Control-Allow-Origin": "*",
  });
  res.end(typeof body === "string" ? body : JSON.stringify(body));
}

function safePublicPath(urlPath) {
  const clean = urlPath.split("?")[0] || "/";
  const rel = clean === "/" ? "index.html" : clean.replace(/^\/+/, "");
  const resolved = path.normalize(path.join(PUBLIC, rel));
  if (!resolved.startsWith(PUBLIC)) return null;
  return resolved;
}

function printBanner() {
  const urls = localAddresses();
  console.log("");
  console.log("  April Web Radar");
  console.log("  ─────────────────────────────────────");
  for (const u of urls) console.log(`  ${u}`);
  console.log(`  Data file: ${radarFilePath()}`);
  console.log("  Keep this window open while using the radar.");
  console.log("");
}

function pidsOnPort(port) {
  const pids = new Set();
  if (process.platform === "win32") {
    try {
      const out = execSync(`netstat -ano -p tcp | findstr :${port}`, { encoding: "utf8" });
      for (const line of out.split(/\r?\n/)) {
        if (!/LISTENING/i.test(line)) continue;
        const parts = line.trim().split(/\s+/);
        const pid = Number(parts[parts.length - 1]);
        if (pid > 0) pids.add(pid);
      }
    } catch {
      /* nothing listening */
    }
    return pids;
  }

  try {
    const out = execSync(`lsof -ti tcp:${port} -sTCP:LISTEN`, { encoding: "utf8" });
    for (const line of out.split(/\r?\n/)) {
      const pid = Number(line.trim());
      if (pid > 0) pids.add(pid);
    }
  } catch {
    /* nothing listening */
  }
  return pids;
}

function killPortListeners(port) {
  const self = process.pid;
  for (const pid of pidsOnPort(port)) {
    if (pid === self) continue;
    try {
      if (process.platform === "win32") {
        execSync(`taskkill /PID ${pid} /F`, { stdio: "ignore" });
      } else {
        process.kill(pid, "SIGTERM");
      }
      console.log(`  Closed previous server on port ${port} (PID ${pid})`);
    } catch {
      /* already gone */
    }
  }
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function readRadarFile() {
  const fp = radarFilePath();
  try {
    const stat = fs.statSync(fp);
    if (radarCache.raw && stat.mtimeMs === radarCache.mtimeMs) {
      return radarCache.raw;
    }

    const raw = fs.readFileSync(fp, "utf8");
    if (!raw || raw.length < 8) return radarCache.raw;

    const parsed = JSON.parse(raw);
    if (!parsed || parsed.ok !== true) return radarCache.raw;

    radarCache.raw = raw;
    radarCache.mtimeMs = stat.mtimeMs;
    radarCache.seq = parsed.seq ?? radarCache.seq;
    return raw;
  } catch {
    return radarCache.raw;
  }
}

function watchRadarFile() {
  const fp = radarFilePath();
  const dir = path.dirname(fp);
  try {
    fs.mkdirSync(dir, { recursive: true });
  } catch {
    /* ignore */
  }

  try {
    fs.watch(dir, (_event, name) => {
      if (!name || String(name).includes("April_web_radar")) {
        readRadarFile();
      }
    });
  } catch {
    setInterval(readRadarFile, 50);
  }
}

async function startServer() {
  killPortListeners(BASE_PORT);
  await sleep(350);
  watchRadarFile();

  const server = http.createServer((req, res) => {
    const url = req.url || "/";

    if (url.startsWith("/api/radar")) {
      const cached = readRadarFile();
      if (!cached) {
        sendJson(res, 200, {
          ok: false,
          waiting: true,
          t: Date.now(),
          message: "Waiting for April in-game data…",
          dataPath: radarFilePath(),
          hostUrls: localAddresses(),
        });
        return;
      }
      sendJson(res, 200, cached);
      return;
    }

    if (url.startsWith("/api/info")) {
      sendJson(res, 200, {
        ok: true,
        port: PORT,
        pid: process.pid,
        dataPath: radarFilePath(),
        hostUrls: localAddresses(),
        seq: radarCache.seq,
      });
      return;
    }

    const file = safePublicPath(url);
    if (!file) {
      res.writeHead(403);
      res.end("Forbidden");
      return;
    }

    fs.readFile(file, (err, data) => {
      if (err) {
        res.writeHead(404);
        res.end("Not found");
        return;
      }
      const ext = path.extname(file).toLowerCase();
      res.writeHead(200, {
        "Content-Type": MIME[ext] || "application/octet-stream",
        "Cache-Control": ext === ".html" || ext === ".js" || ext === ".css" ? "no-cache" : "public, max-age=3600",
      });
      res.end(data);
    });
  });

  for (let attempt = 0; attempt < 5; attempt += 1) {
    PORT = BASE_PORT + attempt;
    try {
      await new Promise((resolve, reject) => {
        const onError = (err) => {
          server.off("listening", onListening);
          reject(err);
        };
        const onListening = () => {
          server.off("error", onError);
          resolve();
        };
        server.once("error", onError);
        server.once("listening", onListening);
        server.listen(PORT, HOST);
      });
      printBanner();
      return;
    } catch (err) {
      if (err.code !== "EADDRINUSE") throw err;
      killPortListeners(PORT);
      await sleep(350);
    }
  }

  console.error("");
  console.error(`  Could not bind ports ${BASE_PORT}-${BASE_PORT + 4}.`);
  console.error("  Close other apps using those ports and try again.");
  console.error("");
  process.exit(1);
}

startServer().catch((err) => {
  console.error(err);
  process.exit(1);
});
