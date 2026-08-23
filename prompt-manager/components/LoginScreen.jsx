"use client";

import { LockKeyhole, Loader2 } from "lucide-react";
import { useState } from "react";
import toast from "react-hot-toast";

export default function LoginScreen({ onLogin }) {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);

  async function submit(event) {
    event.preventDefault();
    setLoading(true);
    try {
      const response = await fetch("/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username, password }),
      });
      const data = await response.json();
      if (!response.ok) throw new Error(data.error || "No se pudo iniciar sesión");
      toast.success("Sesión iniciada");
      onLogin(data.user);
    } catch (error) {
      toast.error(error.message);
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="grid min-h-screen place-items-center bg-[radial-gradient(circle_at_15%_10%,rgba(19,200,223,0.18),transparent_28%),linear-gradient(135deg,#050b16,#0b1220_48%,#07111f)] p-6">
      <form onSubmit={submit} className="w-full max-w-md rounded-lg border border-slate-700/80 bg-slate-950/80 p-8 shadow-2xl shadow-black/40 backdrop-blur">
        <div className="mb-8 flex items-center gap-3">
          <div className="grid h-11 w-11 place-items-center rounded-md bg-cyanbrand text-ink">
            <LockKeyhole size={22} />
          </div>
          <div>
            <h1 className="text-xl font-semibold text-white">Prompt Manager</h1>
            <p className="text-sm text-slate-400">Acceso interno NICOP</p>
          </div>
        </div>

        <label className="mb-4 block">
          <span className="mb-2 block text-sm text-slate-300">Usuario</span>
          <input
            value={username}
            onChange={(event) => setUsername(event.target.value)}
            autoComplete="username"
            className="h-11 w-full rounded-md border border-slate-700 bg-slate-900 px-3 text-white outline-none transition focus:border-cyanbrand"
            placeholder="angel"
          />
        </label>

        <label className="mb-6 block">
          <span className="mb-2 block text-sm text-slate-300">Contraseña</span>
          <input
            type="password"
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            autoComplete="current-password"
            className="h-11 w-full rounded-md border border-slate-700 bg-slate-900 px-3 text-white outline-none transition focus:border-cyanbrand"
            placeholder="••••••••"
          />
        </label>

        <button
          type="submit"
          disabled={loading}
          className="flex h-11 w-full items-center justify-center gap-2 rounded-md bg-bluebrand font-semibold text-white transition hover:bg-blue-500 disabled:cursor-not-allowed disabled:opacity-60"
        >
          {loading && <Loader2 className="animate-spin" size={18} />}
          Entrar
        </button>
      </form>
    </main>
  );
}
