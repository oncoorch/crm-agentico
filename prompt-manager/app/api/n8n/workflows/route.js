import { requireUser } from "@/lib/auth";
import { query } from "@/lib/db";
import { errorResponse, json } from "@/lib/http";

export async function GET() {
  try {
    await requireUser();
    const result = await query(`
      select id, name, active, nodes::jsonb as nodes
      from workflow_entity
      order by name asc
    `);

    const workflows = result.rows.map((workflow) => ({
      id: workflow.id,
      name: workflow.name,
      active: workflow.active,
      nodes: Array.isArray(workflow.nodes)
        ? workflow.nodes.map((node) => ({
          id: node.id,
          name: node.name,
          type: node.type,
        })).filter((node) => node.name)
        : [],
    }));

    return json({ workflows });
  } catch (error) {
    return errorResponse(error);
  }
}
