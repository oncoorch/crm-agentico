#!/usr/bin/env node
import bcrypt from "bcryptjs";

const args = process.argv.slice(2);

if (args.length === 0) {
  console.error("Usage: node scripts/create-users.mjs username:password:role [username:password:role...]");
  console.error("Example: node scripts/create-users.mjs angel:StrongPass123:superadmin jairo:StrongPass456:editor");
  process.exit(1);
}

const users = await Promise.all(args.map(async (arg) => {
  const [username, password, role = "editor"] = arg.split(":");
  if (!username || !password) {
    throw new Error(`Invalid user spec: ${arg}`);
  }
  return {
    username,
    name: username,
    role,
    passwordHash: await bcrypt.hash(password, 12),
  };
}));

const json = JSON.stringify(users);
console.log(Buffer.from(json, "utf8").toString("base64"));
