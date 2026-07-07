import { createFileRoute } from "@tanstack/react-router";

const COACHIO_URL = "https://api.coachio.ai/api/v1/llm/chat/completions";
const MODEL = "google/gemini-3.1-flash-lite";

/**
 * Lightweight key validation. Makes a minimal chat completion so the Settings
 * panel can tell the user "your key works" without generating a full lesson.
 */
export const Route = createFileRoute("/api/test-key")({
  server: {
    handlers: {
      POST: async ({ request }) => {
        const apiKey = request.headers.get("x-coachio-key")?.trim() || process.env.COACHIO_API_KEY;
        if (!apiKey) {
          return Response.json({ ok: false, error: "No API key provided" }, { status: 400 });
        }

        let upstream: Response;
        try {
          upstream = await fetch(COACHIO_URL, {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              "X-API-Key": apiKey,
            },
            body: JSON.stringify({
              model: MODEL,
              stream: false,
              max_tokens: 1,
              messages: [{ role: "user", content: "ping" }],
            }),
          });
        } catch (e) {
          return Response.json(
            { ok: false, error: e instanceof Error ? e.message : "Network error" },
            { status: 502 },
          );
        }

        if (!upstream.ok) {
          const detail = await upstream.text().catch(() => "");
          const hint =
            upstream.status === 401 || upstream.status === 403
              ? "Invalid or unauthorized API key"
              : `Coachio ${upstream.status}`;
          return Response.json(
            { ok: false, error: hint, detail: detail.slice(0, 300) },
            { status: upstream.status },
          );
        }

        return Response.json({ ok: true, model: MODEL });
      },
    },
  },
});
