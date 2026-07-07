import { createFileRoute } from "@tanstack/react-router";
import { getAdminClient } from "@/lib/supabase-admin";
import { serverBaseUrl, json } from "@/lib/oauth";

/**
 * Deploy diagnostic — reports which server env vars are present (booleans only,
 * never their values). Hit /api/mcp-health after deploying to confirm the MCP
 * server is configured. Safe to leave public: it leaks no secrets.
 */
export const Route = createFileRoute("/api/mcp-health")({
  server: {
    handlers: {
      GET: async ({ request }) => {
        const admin = getAdminClient();
        const env = {
          SUPABASE_URL: !!(process.env.SUPABASE_URL || process.env.VITE_SUPABASE_URL),
          SUPABASE_SERVICE_ROLE_KEY: !!process.env.SUPABASE_SERVICE_ROLE_KEY,
          PUBLIC_APP_URL: !!process.env.PUBLIC_APP_URL,
          COACHIO_API_KEY: !!process.env.COACHIO_API_KEY,
        };
        let dbReachable: boolean | null = null;
        if (admin) {
          const { error } = await admin.from("oauth_clients").select("client_id").limit(1);
          dbReachable = !error;
        }
        return json({
          ok: !!admin && dbReachable === true,
          baseUrl: serverBaseUrl(request),
          adminClient: admin
            ? "configured"
            : "NOT configured — set SUPABASE_SERVICE_ROLE_KEY (+ SUPABASE_URL)",
          env,
          dbReachable,
        });
      },
    },
  },
});
