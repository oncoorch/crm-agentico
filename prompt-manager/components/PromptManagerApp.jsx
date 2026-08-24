"use client";

import { CheckCircle2, Clock3, FileDown, History, Loader2, LogOut, Save, Search } from "lucide-react";
import { useEffect, useMemo, useRef, useState } from "react";
import ReactMarkdown from "react-markdown";
import toast, { Toaster } from "react-hot-toast";
import remarkGfm from "remark-gfm";
import MarkdownToolbar from "./MarkdownToolbar";
import LoginScreen from "./LoginScreen";

const defaultPrompt = `# System Prompt\n\nEscribe aquí el prompt del agente.\n\n- Sé claro.\n- Evita repetir mensajes.\n- Cierra con un siguiente paso concreto.`;

export default function PromptManagerApp() {
  const [user, setUser] = useState(null);
  const [checkingAuth, setCheckingAuth] = useState(true);
  const [workflows, setWorkflows] = useState([]);
  const [promptEntries, setPromptEntries] = useState([]);
  const [workflowId, setWorkflowId] = useState("");
  const [nodeName, setNodeName] = useState("");
  const [parameterKey, setParameterKey] = useState("waba_system_promt");
  const [redisDb, setRedisDb] = useState(1);
  const [prompt, setPrompt] = useState(defaultPrompt);
  const [savedPrompt, setSavedPrompt] = useState(defaultPrompt);
  const [loadingPrompt, setLoadingPrompt] = useState(false);
  const [saving, setSaving] = useState(false);
  const [audit, setAudit] = useState([]);
  const textareaRef = useRef(null);

  const selectedWorkflow = useMemo(
    () => workflows.find((workflow) => workflow.id === workflowId),
    [workflows, workflowId],
  );
  const dirty = prompt !== savedPrompt;

  useEffect(() => {
    fetch("/api/auth/me")
      .then((response) => response.json())
      .then((data) => {
        setUser(data.user);
        if (data.user) {
          loadWorkflows();
          loadPromptEntries();
          loadAudit();
        }
      })
      .finally(() => setCheckingAuth(false));
  }, []);

  async function loadWorkflows() {
    const response = await fetch("/api/n8n/workflows");
    if (!response.ok) return;
    const data = await response.json();
    setWorkflows(data.workflows || []);
    const komodo = data.workflows?.find((workflow) => workflow.id === "61fvbcCLHObsy3Tm" || /komodo/i.test(workflow.name));
    if (komodo) {
      setWorkflowId(komodo.id);
      const systemNode = komodo.nodes.find((node) => /system prom/i.test(node.name)) || komodo.nodes[0];
      setNodeName(systemNode?.name || "");
    }
  }

  async function loadPromptEntries() {
    const response = await fetch("/api/prompts");
    if (!response.ok) return;
    const data = await response.json();
    const entries = data.prompts || [];
    setPromptEntries(entries);
    const komodoPrompt = entries.find((entry) => entry.key === "waba_system_promt") || entries[0];
    if (komodoPrompt) {
      applyPromptEntry(komodoPrompt);
      loadPrompt(komodoPrompt.key, komodoPrompt.redis_db || 1);
    }
  }

  function applyPromptEntry(entry) {
    setParameterKey(entry.key || "");
    setRedisDb(entry.redis_db || 1);
    setWorkflowId(entry.workflow_id || "");
    setNodeName(entry.node_name || "");
  }

  async function loadAudit() {
    const response = await fetch("/api/audit");
    if (!response.ok) return;
    const data = await response.json();
    setAudit(data.entries || []);
  }

  async function loadPrompt(nextKey = parameterKey, nextRedisDb = redisDb) {
    if (!String(nextKey || "").trim()) {
      toast.error("Falta el Parameter Key");
      return;
    }
    setLoadingPrompt(true);
    try {
      const params = new URLSearchParams({ parameterKey: nextKey, redisDb: String(nextRedisDb) });
      const response = await fetch(`/api/prompts?${params}`);
      const data = await response.json();
      if (!response.ok) throw new Error(data.error || "No se pudo cargar");
      if (data.registeredPrompt) {
        applyPromptEntry(data.registeredPrompt);
      }
      setPrompt(data.prompt || "");
      setSavedPrompt(data.prompt || "");
      toast.success(data.sources?.postgres?.found ? "Prompt cargado desde registro estable" : "Prompt cargado");
    } catch (error) {
      toast.error(error.message);
    } finally {
      setLoadingPrompt(false);
    }
  }

  async function savePrompt() {
    if (!parameterKey.trim()) {
      toast.error("Falta el Parameter Key");
      return;
    }
    setSaving(true);
    try {
      const response = await fetch("/api/prompts", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          workflowId,
          workflowName: selectedWorkflow?.name || "",
          nodeName,
          parameterKey,
          redisDb: Number(redisDb),
          prompt,
        }),
      });
      const data = await response.json();
      if (!response.ok) throw new Error(data.error || "No se pudo guardar");
      setSavedPrompt(prompt);
      toast.success("Prompt guardado correctamente");
      loadPromptEntries();
      loadAudit();
    } catch (error) {
      toast.error(error.message);
    } finally {
      setSaving(false);
    }
  }

  async function logout() {
    await fetch("/api/auth/logout", { method: "POST" });
    setUser(null);
  }

  if (checkingAuth) {
    return (
      <main className="grid min-h-screen place-items-center bg-ink text-slate-200">
        <Loader2 className="animate-spin" />
      </main>
    );
  }

  if (!user) {
    return (
      <>
        <Toaster position="top-right" />
        <LoginScreen onLogin={(nextUser) => {
          setUser(nextUser);
          loadWorkflows();
          loadPromptEntries();
          loadAudit();
        }} />
      </>
    );
  }

  return (
    <main className="flex h-screen flex-col overflow-hidden bg-[#07111f] text-slate-100">
      <Toaster position="top-right" toastOptions={{ style: { background: "#0f172a", color: "#e2e8f0", border: "1px solid #334155" } }} />

      <header className="flex h-16 shrink-0 items-center justify-between border-b border-slate-800 bg-slate-950 px-5">
        <div className="flex items-center gap-3">
          <div className="grid h-9 w-9 place-items-center rounded-md bg-cyanbrand text-ink font-black">P</div>
          <div>
            <h1 className="text-lg font-semibold text-white">Prompt Manager</h1>
            <p className="text-xs text-slate-400">System prompts para agentes NICOP</p>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <span className={`flex items-center gap-1.5 rounded-full px-3 py-1 text-xs ${dirty ? "bg-amber-500/10 text-amber-200" : "bg-emerald-500/10 text-emerald-200"}`}>
            {dirty ? <Clock3 size={14} /> : <CheckCircle2 size={14} />}
            {dirty ? "Editando..." : "Guardado"}
          </span>
          <button
            onClick={savePrompt}
            disabled={saving}
            className="flex h-10 items-center gap-2 rounded-md bg-bluebrand px-4 text-sm font-semibold text-white transition hover:bg-blue-500 disabled:opacity-60"
          >
            {saving ? <Loader2 className="animate-spin" size={16} /> : <Save size={16} />}
            Guardar Cambios
          </button>
          <button onClick={logout} title="Salir" className="grid h-10 w-10 place-items-center rounded-md border border-slate-700 text-slate-300 hover:bg-slate-900">
            <LogOut size={17} />
          </button>
        </div>
      </header>

      <section className="grid shrink-0 grid-cols-[1.2fr_1fr_1fr_120px_120px] gap-3 border-b border-slate-800 bg-slate-900/70 px-5 py-3">
        <label className="block">
          <span className="mb-1 block text-xs font-medium text-slate-400">Prompt registrado</span>
          <select
            value={parameterKey}
            onChange={(event) => {
              const entry = promptEntries.find((item) => item.key === event.target.value);
              if (entry) applyPromptEntry(entry);
            }}
            className="h-10 w-full rounded-md border border-slate-700 bg-slate-950 px-3 text-sm outline-none focus:border-cyanbrand"
          >
            <option value="">Seleccionar prompt</option>
            {promptEntries.map((entry) => (
              <option key={entry.key} value={entry.key}>
                {(entry.workflow_name || "Workflow")} / {(entry.node_name || "Nodo")} / {entry.key}
              </option>
            ))}
          </select>
        </label>
        <label className="block">
          <span className="mb-1 block text-xs font-medium text-slate-400">Workflow Name</span>
          <select value={workflowId} onChange={(event) => { setWorkflowId(event.target.value); setNodeName(""); }} className="h-10 w-full rounded-md border border-slate-700 bg-slate-950 px-3 text-sm outline-none focus:border-cyanbrand">
            <option value="">Seleccionar workflow</option>
            {workflows.map((workflow) => (
              <option key={workflow.id} value={workflow.id}>{workflow.name}{workflow.active ? " · activo" : ""}</option>
            ))}
          </select>
        </label>
        <label className="block">
          <span className="mb-1 block text-xs font-medium text-slate-400">Node Name</span>
          <select value={nodeName} onChange={(event) => setNodeName(event.target.value)} className="h-10 w-full rounded-md border border-slate-700 bg-slate-950 px-3 text-sm outline-none focus:border-cyanbrand">
            <option value="">Seleccionar nodo</option>
            {(selectedWorkflow?.nodes || []).map((node) => (
              <option key={node.id || node.name} value={node.name}>{node.name}</option>
            ))}
          </select>
        </label>
        <label className="block">
          <span className="mb-1 block text-xs font-medium text-slate-400">Redis DB</span>
          <input type="number" min="0" max="15" value={redisDb} onChange={(event) => setRedisDb(event.target.value)} className="h-10 w-full rounded-md border border-slate-700 bg-slate-950 px-3 text-sm outline-none focus:border-cyanbrand" />
        </label>
        <button onClick={() => loadPrompt()} disabled={loadingPrompt} className="mt-5 flex h-10 items-center justify-center gap-2 rounded-md border border-cyanbrand/70 bg-cyanbrand/10 text-sm font-semibold text-cyan-100 transition hover:bg-cyanbrand/20 disabled:opacity-60">
          {loadingPrompt ? <Loader2 className="animate-spin" size={16} /> : <Search size={16} />}
          Cargar
        </button>
      </section>

      <section className="grid min-h-0 flex-1 grid-cols-2">
        <div className="flex min-h-0 flex-col border-r border-slate-800">
          <MarkdownToolbar textareaRef={textareaRef} value={prompt} onChange={setPrompt} />
          <textarea
            ref={textareaRef}
            value={prompt}
            onChange={(event) => setPrompt(event.target.value)}
            spellCheck={false}
            className="editor-scroll min-h-0 flex-1 resize-none bg-slate-950 p-5 font-mono text-sm leading-6 text-slate-100 outline-none"
          />
        </div>
        <div className="editor-scroll min-h-0 overflow-auto bg-slate-900 p-6">
          <div className="prose prose-invert prose-slate max-w-none prose-headings:text-white prose-a:text-cyan-300 prose-strong:text-white">
            <ReactMarkdown remarkPlugins={[remarkGfm]}>{prompt || " "}</ReactMarkdown>
          </div>
        </div>
      </section>

      <aside className="h-28 shrink-0 border-t border-slate-800 bg-slate-950/95 px-5 py-3">
        <div className="mb-2 flex items-center justify-between">
          <div className="flex items-center gap-2 text-sm font-semibold text-slate-200">
            <History size={16} />
            Historial reciente
          </div>
          <button onClick={loadAudit} className="flex items-center gap-2 text-xs text-slate-400 hover:text-white">
            <FileDown size={14} />
            Actualizar
          </button>
        </div>
        <div className="editor-scroll flex gap-2 overflow-x-auto pb-1">
          {audit.slice(0, 8).map((entry) => (
            <div key={entry.id} className="min-w-[270px] rounded-md border border-slate-800 bg-slate-900 px-3 py-2 text-xs">
              <div className="truncate font-medium text-white">{entry.parameter_key}</div>
              <div className="truncate text-slate-400">{entry.username} · {entry.workflow_name || "workflow"} · {entry.node_name || "nodo"}</div>
              <div className="text-slate-500">{new Date(entry.changed_at).toLocaleString()} · {entry.previous_length} → {entry.new_length} chars</div>
            </div>
          ))}
        </div>
      </aside>
    </main>
  );
}
