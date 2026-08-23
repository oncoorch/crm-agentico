export function requiredEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing environment variable: ${name}`);
  }
  return value;
}

export function optionalEnv(name, fallback = "") {
  return process.env[name] || fallback;
}

export function parseUsers() {
  const encoded = process.env.PROMPT_MANAGER_USERS_B64;
  const raw = encoded
    ? Buffer.from(encoded, "base64").toString("utf8")
    : process.env.PROMPT_MANAGER_USERS_JSON;

  if (!raw || raw.startsWith("change_me")) {
    return [];
  }

  const parsed = JSON.parse(raw);
  if (!Array.isArray(parsed)) {
    throw new Error("PROMPT_MANAGER_USERS must be an array");
  }

  return parsed.map((user) => ({
    username: String(user.username || "").trim(),
    name: String(user.name || user.username || "").trim(),
    role: String(user.role || "editor").trim(),
    passwordHash: String(user.passwordHash || "").trim(),
  })).filter((user) => user.username && user.passwordHash);
}
