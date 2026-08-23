import { NextResponse } from "next/server";

export function json(data, init = {}) {
  return NextResponse.json(data, init);
}

export function errorResponse(error) {
  const status = error?.status || 500;
  return json({ error: error?.message || "Unexpected error" }, { status });
}
