-- ============================================================================
-- Lumi — Complete database setup
-- Run ONCE in the Supabase dashboard → SQL Editor → New query → Run.
-- Safe to re-run (idempotent). Sets up every feature: progress sync, saved
-- lessons, public share links, and the OAuth/MCP server.
-- ============================================================================

-- ─────────────────────────────────────────────────────────────
-- 1) PROGRESS — one row per user (XP, streak, badges, daily quests)
-- ─────────────────────────────────────────────────────────────
create table if not exists public.progress (
  user_id     uuid primary key references auth.users (id) on delete cascade,
  xp          integer     not null default 0,
  streak      integer     not null default 0,
  last_active date,
  badges      text[]      not null default '{}',
  quests      jsonb       not null default '[]'::jsonb,
  updated_at  timestamptz not null default now()
);

alter table public.progress enable row level security;

drop policy if exists "progress_select_own" on public.progress;
create policy "progress_select_own"
  on public.progress for select using (auth.uid() = user_id);

drop policy if exists "progress_insert_own" on public.progress;
create policy "progress_insert_own"
  on public.progress for insert with check (auth.uid() = user_id);

drop policy if exists "progress_update_own" on public.progress;
create policy "progress_update_own"
  on public.progress for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ─────────────────────────────────────────────────────────────
-- 2) LESSONS — saved lessons + share visibility (private/public)
-- ─────────────────────────────────────────────────────────────
create table if not exists public.lessons (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  title       text not null default 'Untitled lesson',
  topic       text,
  level       text,
  source      text,                                  -- the prompt/source the user pasted
  data        jsonb not null,                        -- the full Lesson object
  visibility  text  not null default 'private',      -- 'private' | 'public'
  created_at  timestamptz not null default now()
);

-- Safety for older databases that created the table before `visibility` existed.
alter table public.lessons add column if not exists visibility text not null default 'private';

create index if not exists lessons_user_created_idx
  on public.lessons (user_id, created_at desc);

alter table public.lessons enable row level security;

-- Owner reads their own lessons.
drop policy if exists "lessons_select_own" on public.lessons;
create policy "lessons_select_own"
  on public.lessons for select using (auth.uid() = user_id);

-- Anyone (even anonymous) can read a PUBLIC lesson — this powers share links.
drop policy if exists "lessons_select_public" on public.lessons;
create policy "lessons_select_public"
  on public.lessons for select using (visibility = 'public');

drop policy if exists "lessons_insert_own" on public.lessons;
create policy "lessons_insert_own"
  on public.lessons for insert with check (auth.uid() = user_id);

drop policy if exists "lessons_update_own" on public.lessons;
create policy "lessons_update_own"
  on public.lessons for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "lessons_delete_own" on public.lessons;
create policy "lessons_delete_own"
  on public.lessons for delete using (auth.uid() = user_id);

-- ─────────────────────────────────────────────────────────────
-- 3) OAUTH 2.1 — powers the MCP connector for Claude/ChatGPT.
--    Touched ONLY by the server (service-role key). RLS is enabled with NO
--    policies, so anon/authenticated clients can never read tokens.
--    (Optional: only needed if you set up the Claude/ChatGPT MCP connector.)
-- ─────────────────────────────────────────────────────────────
create table if not exists public.oauth_clients (
  client_id      text primary key,
  client_secret  text,
  client_name    text,
  redirect_uris  text[] not null default '{}',
  created_at     timestamptz not null default now()
);

create table if not exists public.oauth_codes (
  code                   text primary key,
  client_id              text not null,
  user_id                uuid not null references auth.users (id) on delete cascade,
  redirect_uri           text,
  code_challenge         text,
  code_challenge_method  text,
  scope                  text,
  expires_at             timestamptz not null,
  created_at             timestamptz not null default now()
);

create table if not exists public.oauth_tokens (
  access_token   text primary key,
  refresh_token  text unique,
  client_id      text not null,
  user_id        uuid not null references auth.users (id) on delete cascade,
  scope          text,
  expires_at     timestamptz not null,
  created_at     timestamptz not null default now()
);

alter table public.oauth_clients enable row level security;
alter table public.oauth_codes   enable row level security;
alter table public.oauth_tokens  enable row level security;

-- ─────────────────────────────────────────────────────────────
-- 4) MCP_DEBUG — request log for troubleshooting the connector.
--    Optional, stores no secrets. You can drop it later:  drop table public.mcp_debug;
-- ─────────────────────────────────────────────────────────────
create table if not exists public.mcp_debug (
  id               bigint generated always as identity primary key,
  ts               timestamptz not null default now(),
  method           text,
  accept           text,
  has_auth         boolean,
  auth_valid       boolean,
  protocol_version text,
  session_id       text,
  user_agent       text,
  note             text
);
alter table public.mcp_debug enable row level security;

-- ============================================================================
-- Done. Next steps for a fresh setup:
--   1) Enable Email auth:  Authentication → Providers → Email (on).
--      For easy testing, turn OFF "Confirm email".
--   2) Copy your keys into the app's .env  (Project Settings → API):
--        VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY
--        SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY   (server-side, for OAuth/MCP)
-- ============================================================================
