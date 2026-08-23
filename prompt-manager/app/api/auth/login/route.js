import { createSession, login, setSessionCookie } from "@/lib/auth";
import { errorResponse, json } from "@/lib/http";

export async function POST(request) {
  try {
    const body = await request.json();
    const user = await login(body.username, body.password);
    if (!user) {
      return json({ error: "Credenciales inválidas" }, { status: 401 });
    }

    await setSessionCookie(createSession(user));
    return json({ user: { username: user.username, name: user.name, role: user.role } });
  } catch (error) {
    return errorResponse(error);
  }
}
