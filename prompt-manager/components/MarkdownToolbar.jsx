"use client";

import { Bold, Italic, Link, List, Underline } from "lucide-react";

const tools = [
  { label: "Negrita", icon: Bold, before: "**", after: "**", fallback: "texto en negrita" },
  { label: "Cursiva", icon: Italic, before: "*", after: "*", fallback: "texto en cursiva" },
  { label: "Subrayado", icon: Underline, before: "<u>", after: "</u>", fallback: "texto subrayado" },
  { label: "Enlace", icon: Link, before: "[", after: "](https://)", fallback: "texto del enlace" },
  { label: "Viñeta", icon: List, block: "- " },
];

export default function MarkdownToolbar({ textareaRef, value, onChange }) {
  function applyTool(tool) {
    const textarea = textareaRef.current;
    if (!textarea) return;

    const start = textarea.selectionStart;
    const end = textarea.selectionEnd;
    const selected = value.slice(start, end);

    let next;
    let cursorStart;
    let cursorEnd;

    if (tool.block) {
      const lineStart = value.lastIndexOf("\n", start - 1) + 1;
      next = `${value.slice(0, lineStart)}${tool.block}${value.slice(lineStart)}`;
      cursorStart = start + tool.block.length;
      cursorEnd = end + tool.block.length;
    } else {
      const content = selected || tool.fallback;
      next = `${value.slice(0, start)}${tool.before}${content}${tool.after}${value.slice(end)}`;
      cursorStart = start + tool.before.length;
      cursorEnd = cursorStart + content.length;
    }

    onChange(next);
    requestAnimationFrame(() => {
      textarea.focus();
      textarea.setSelectionRange(cursorStart, cursorEnd);
    });
  }

  return (
    <div className="flex items-center gap-1 border-b border-slate-800 bg-slate-950/80 px-3 py-2">
      {tools.map((tool) => {
        const Icon = tool.icon;
        return (
          <button
            key={tool.label}
            type="button"
            title={tool.label}
            onClick={() => applyTool(tool)}
            className="grid h-8 w-8 place-items-center rounded-md text-slate-300 transition hover:bg-slate-800 hover:text-white"
          >
            <Icon size={16} />
          </button>
        );
      })}
    </div>
  );
}
