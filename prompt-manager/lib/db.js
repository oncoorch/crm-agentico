import pg from "pg";
import Redis from "ioredis";
import crypto from "node:crypto";
import { optionalEnv, requiredEnv } from "./env";

const { Pool } = pg;

function pgPool() {
  if (!globalThis.__promptManagerPgPool) {
    globalThis.__promptManagerPgPool = new Pool({
      host: optionalEnv("PROMPT_MANAGER_PG_HOST", "n8n_postgres"),
      port: Number(optionalEnv("PROMPT_MANAGER_PG_PORT", "5432")),
      database: optionalEnv("PROMPT_MANAGER_PG_DATABASE", "n8n_production"),
      user: optionalEnv("PROMPT_MANAGER_PG_USER", "n8n"),
      password: requiredEnv("PROMPT_MANAGER_PG_PASSWORD"),
      max: 8,
      idleTimeoutMillis: 30_000,
    });
  }
  return globalThis.__promptManagerPgPool;
}

export async function query(sql, params = []) {
  return pgPool().query(sql, params);
}

export function redisClient(db = 1) {
  return new Redis({
    host: optionalEnv("PROMPT_MANAGER_REDIS_HOST", "n8n_redis"),
    port: Number(optionalEnv("PROMPT_MANAGER_REDIS_PORT", "6379")),
    password: requiredEnv("PROMPT_MANAGER_REDIS_PASSWORD"),
    db: Number(db || optionalEnv("PROMPT_MANAGER_REDIS_DB", "1")),
    lazyConnect: true,
    maxRetriesPerRequest: 2,
  });
}

export function assertIdentifier(value, fallback) {
  const identifier = String(value || fallback || "").trim();
  if (!/^[a-zA-Z_][a-zA-Z0-9_]*$/.test(identifier)) {
    throw new Error(`Invalid SQL identifier: ${identifier}`);
  }
  return identifier;
}

export async function ensureAuditTable() {
  await query(`
    create table if not exists public.prompt_manager_audit (
      id bigserial primary key,
      changed_at timestamptz not null default now(),
      username text not null,
      workflow_id text,
      workflow_name text,
      node_name text,
      parameter_key text not null,
      redis_db integer not null default 1,
      previous_hash text,
      new_hash text not null,
      previous_length integer not null default 0,
      new_length integer not null default 0,
      action text not null default 'save',
      metadata jsonb not null default '{}'::jsonb
    );
  `);
}

export function sha256(value) {
  return crypto.createHash("sha256").update(value).digest("hex");
}
