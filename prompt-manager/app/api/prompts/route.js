import { requireUser } from "@/lib/auth";
import { assertIdentifier, ensureAuditTable, query, redisClient, sha256 } from "@/lib/db";
import { errorResponse, json } from "@/lib/http";

function normalizeKey(value) {
  const key = String(value || "").trim();
  if (!key) {
    const error = new Error("Falta el Parameter Key");
    error.status = 400;
    throw error;
  }
  return key;
}

async function readPostgresPrompt(key, tableName) {
  const table = assertIdentifier(tableName, "parameters");
  const result = await query(`select value, description, updated_at from public.${table} where key = $1 limit 1`, [key]);
  return result.rows[0] || null;
}

export async function GET(request) {
  try {
    await requireUser();
    const { searchParams } = new URL(request.url);
    const key = normalizeKey(searchParams.get("parameterKey"));
    const redisDb = Number(searchParams.get("redisDb") || 1);
    const table = searchParams.get("postgresTable") || "parameters";

    let redisValue = null;
    const redis = redisClient(redisDb);
    try {
      await redis.connect();
      redisValue = await redis.get(key);
    } finally {
      redis.disconnect();
    }

    const postgresValue = await readPostgresPrompt(key, table);
    const prompt = redisValue ?? postgresValue?.value ?? "";

    return json({
      parameterKey: key,
      redisDb,
      prompt,
      sources: {
        redis: { found: redisValue !== null, length: redisValue?.length || 0 },
        postgres: { found: Boolean(postgresValue), length: postgresValue?.value?.length || 0, updatedAt: postgresValue?.updated_at || null },
      },
    });
  } catch (error) {
    return errorResponse(error);
  }
}

export async function POST(request) {
  try {
    const user = await requireUser();
    const body = await request.json();
    const key = normalizeKey(body.parameterKey);
    const prompt = String(body.prompt || "");
    const redisDb = Number(body.redisDb || 1);
    const table = assertIdentifier(body.postgresTable, "parameters");
    const workflowId = String(body.workflowId || "").trim();
    const workflowName = String(body.workflowName || "").trim();
    const nodeName = String(body.nodeName || "").trim();
    const description = `Updated by Prompt Manager for ${workflowName || "workflow"} / ${nodeName || "node"}`;

    await ensureAuditTable();
    const previous = await readPostgresPrompt(key, table);
    const previousValue = previous?.value || "";
    const previousHash = previousValue ? await sha256(previousValue) : null;
    const newHash = await sha256(prompt);

    await query(`
      insert into public.${table} (key, value, description)
      values ($1, $2, $3)
      on conflict (key) do update
      set value = excluded.value,
          description = excluded.description,
          updated_at = now()
    `, [key, prompt, description]);

    const redis = redisClient(redisDb);
    try {
      await redis.connect();
      await redis.set(key, prompt);
    } finally {
      redis.disconnect();
    }

    await query(`
      insert into public.prompt_manager_audit (
        username, workflow_id, workflow_name, node_name, parameter_key, redis_db,
        previous_hash, new_hash, previous_length, new_length, metadata
      )
      values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11::jsonb)
    `, [
      user.username,
      workflowId || null,
      workflowName || null,
      nodeName || null,
      key,
      redisDb,
      previousHash,
      newHash,
      previousValue.length,
      prompt.length,
      JSON.stringify({ source: "prompt-manager" }),
    ]);

    return json({ ok: true, parameterKey: key, length: prompt.length, hash: newHash });
  } catch (error) {
    return errorResponse(error);
  }
}
