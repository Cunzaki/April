#!/usr/bin/env node
/**
 * Sync Chunk Studios (1154360) staff IDs into src/game/mod_ids.lua
 * Includes everyone above Fan rank (rank > 5).
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const GROUP_ID = 1154360;
const MIN_RANK = 6; // above Fan (5)
const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const OUT = path.join(ROOT, "src/game/mod_ids.lua");

async function fetchJson(url) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`${url} -> ${res.status}`);
  return res.json();
}

async function fetchStaffRoles() {
  const json = await fetchJson(`https://groups.roblox.com/v1/groups/${GROUP_ID}/roles`);
  return (json.roles || []).filter((r) => r.rank >= MIN_RANK);
}

async function fetchRoleUsers(roleId) {
  const users = [];
  let cursor = "";
  for (;;) {
    let url = `https://groups.roblox.com/v1/groups/${GROUP_ID}/roles/${roleId}/users?limit=100&sortOrder=Asc`;
    if (cursor) url += `&cursor=${encodeURIComponent(cursor)}`;
    const json = await fetchJson(url);
    for (const row of json.data || []) {
      if (!row.userId) continue;
      users.push({
        userId: row.userId,
        username: row.username || "?",
      });
    }
    cursor = json.nextPageCursor;
    if (!cursor) break;
  }
  return users;
}

async function fetchAllStaff() {
  const roles = await fetchStaffRoles();
  const byRole = new Map();
  for (const role of roles) {
    const users = await fetchRoleUsers(role.id);
    byRole.set(role.name, users);
    console.log(`${role.name}: ${users.length}`);
  }
  return { roles, byRole };
}

function buildLua({ roles, byRole }) {
  const roleOrder = roles.sort((a, b) => b.rank - a.rank).map((r) => r.name);
  const lines = [];
  lines.push("local M = {}");
  lines.push("");
  lines.push(`-- Chunk Studios (${GROUP_ID}) staff ranks above Fan.`);
  lines.push("-- Roles: " + roleOrder.join(", ") + ". Excludes Guest / Member / Fan.");
  lines.push(`-- Synced from groups.roblox.com on ${new Date().toISOString().slice(0, 10)}.`);
  lines.push("M.GROUP_ID = " + GROUP_ID);
  lines.push("M.MIN_STAFF_RANK = " + MIN_RANK);
  lines.push("M.ROLES = {");
  for (const roleName of roleOrder) {
    const users = byRole.get(roleName) || [];
    if (users.length === 0) continue;
    lines.push("");
    lines.push(`    -- ${roleName}`);
    for (const u of users.sort((a, b) => a.userId - b.userId)) {
      lines.push(`    [${u.userId}] = "${roleName}", -- ${u.username}`);
    }
  }
  lines.push("}");
  lines.push("");
  lines.push(`function M.short_label(role)`);
  lines.push(`    if not role then return "STAFF" end`);
  lines.push(`    if role == "Game Moderator" then return "MOD" end`);
  lines.push(`    if role == "Game Tester" then return "TESTER" end`);
  lines.push(`    if role == "Lead Developer" or role == "Developers" then return "DEV" end`);
  lines.push(`    if role == "Co-Founder" then return "CO-FOUNDER" end`);
  lines.push(`    if role == "Founder" then return "FOUNDER" end`);
  lines.push(`    if role == "OG" then return "OG" end`);
  lines.push(`    if role == "Contribution" then return "CONTRIB" end`);
  lines.push(`    return role:upper()`);
  lines.push(`end`);
  lines.push("");
  lines.push(`function M.glyph_kind(role)`);
  lines.push(`    if not role then return "staff" end`);
  lines.push(`    local r = role:lower()`);
  lines.push(`    if r:find("moderator", 1, true) then return "mod" end`);
  lines.push(`    if r:find("tester", 1, true) then return "tester" end`);
  lines.push(`    if r:find("developer", 1, true) or r:find("founder", 1, true) then return "dev" end`);
  lines.push(`    if r == "og" then return "og" end`);
  lines.push(`    if r:find("contribution", 1, true) then return "contrib" end`);
  lines.push(`    return "staff"`);
  lines.push(`end`);
  lines.push("");
  lines.push(`return M`);
  lines.push("");
  return lines.join("\n");
}

const { roles, byRole } = await fetchAllStaff();
let total = 0;
for (const users of byRole.values()) total += users.length;
console.log(`Total staff: ${total}`);

// Note: full mod_ids.lua includes group API logic appended by hand after sync.
// This script only regenerates the STATIC_ROLES block when run with --static-only.
const staticBlock = buildLua({ roles, byRole });
fs.writeFileSync(OUT.replace(".lua", ".static.generated.lua"), staticBlock);
console.log("Wrote static snapshot:", OUT.replace(".lua", ".static.generated.lua"));
