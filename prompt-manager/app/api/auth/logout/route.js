import { clearSessionCookie } from "@/lib/auth";
import { errorResponse, json } from "@/lib/http";

export async function POST() {
  try {
    await clearSessionCookie();
    return json({ ok: true });
  } catch (error) {
    return errorResponse(error);
  }
}
