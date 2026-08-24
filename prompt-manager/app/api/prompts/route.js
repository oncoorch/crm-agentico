import { requireUser } from "@/lib/auth";
import { ensureAgentPromptsTable, ensureAuditTable, query, redisClient, sha256 } from "@/lib/db";
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

async function readAgentPrompt(key) {
  await ensureAgentPromptsTable();
  const result = await query(`
    select key, value, workflow_id, workflow_name, node_name, redis_db, description, active, updated_at
    from public.agent_prompts
    where key = $1 and active = true
    limit 1
  `, [key]);
  return result.rows[0] || null;
}

export async function GET(request) {
  try {
    await requireUser();
    const { searchParams } = new URL(request.url);
    const rawKey = searchParams.get("parameterKey");

    if (!rawKey) {
      await ensureAgentPromptsTable();
      const result = await query(`
        select key, workflow_id, workflow_name, node_name, redis_db, description, updated_at
        from public.agent_prompts
        where active = true
        order by workflow_name nulls last, node_name nulls last, key asc
      `);
      return json({ prompts: result.rows });
    }

    const key = normalizeKey(rawKey);
    const registeredPrompt = await readAgentPrompt(key);
    const redisDb = Number(searchParams.get("redisDb") || registeredPrompt?.redis_db || 1);

    let redisValue = null;
    const redis = redisClient(redisDb);
    try {
      await redis.connect();
      redisValue = await redis.get(key);
    } finally {
      redis.disconnect();
    }

    const prompt = registeredPrompt?.value ?? redisValue ?? "";

    return json({
      parameterKey: key,
      redisDb,
      prompt,
      registeredPrompt,
      sources: {
        redis: { found: redisValue !== null, length: redisValue?.length || 0 },
        postgres: {
          found: Boolean(registeredPrompt),
          length: registeredPrompt?.value?.length || 0,
          updatedAt: registeredPrompt?.updated_at || null,
        },
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
    const workflowId = String(body.workflowId || "").trim();
    const workflowName = String(body.workflowName || "").trim();
    const nodeName = String(body.nodeName || "").trim();
    const description = `Updated by Prompt Manager for ${workflowName || "workflow"} / ${nodeName || "node"}`;

    await ensureAuditTable();
    await ensureAgentPromptsTable();
    const previous = await readAgentPrompt(key);
    const previousValue = previous?.value || "";
    const previousHash = previousValue ? await sha256(previousValue) : null;
    const newHash = await sha256(prompt);

    await query(`
      insert into public.agent_prompts (
        key, value, workflow_id, workflow_name, node_name, redis_db, description, active
      )
      values ($1, $2, $3, $4, $5, $6, $7, true)
      on conflict (key) do update
      set value = excluded.value,
          workflow_id = excluded.workflow_id,
          workflow_name = excluded.workflow_name,
          node_name = excluded.node_name,
          redis_db = excluded.redis_db,
          description = excluded.description,
          active = true,
          updated_at = now()
    `, [key, prompt, workflowId || null, workflowName || null, nodeName || null, redisDb, description]);

    await query(`
      insert into public.parameters (key, value, description)
      values ($1, $2, $3)
      on conflict (key) do update
      set value = excluded.value,
          description = excluded.description,
          updated_at = now()
    `, [key, prompt, `Synced from public.agent_prompts for ${workflowName || "workflow"}`]);

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
