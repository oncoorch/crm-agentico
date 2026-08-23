import { requireUser } from "@/lib/auth";
import { ensureAuditTable, query } from "@/lib/db";
import { errorResponse, json } from "@/lib/http";

export async function GET() {
  try {
    await requireUser();
    await ensureAuditTable();
    const result = await query(`
      select id, changed_at, username, workflow_name, node_name, parameter_key,
             redis_db, previous_hash, new_hash, previous_length, new_length, action
      from public.prompt_manager_audit
      order by changed_at desc
      limit 50
    `);
    return json({ entries: result.rows });
  } catch (error) {
    return errorResponse(error);
  }
}
