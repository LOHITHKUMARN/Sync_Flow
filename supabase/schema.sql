-- ==========================================================
-- 🚀 SyncFlow — Production PostgreSQL Schema & Row Level Security (RLS)
-- Relational Hierarchy:
-- User (profiles) -> Workspace Members -> Projects -> Tasks
-- (Assignee, Comments, Subtasks, Labels, Attachments, Activity, Time Entries)
-- ==========================================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- 1. Profiles Table (Linked to Supabase Auth)
create table if not exists public.profiles (
    id uuid references auth.users on delete cascade primary key,
    email text not null,
    full_name text not null,
    avatar_url text,
    role_title text default 'Product Contributor',
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.profiles enable row level security;

create policy "Public profiles are viewable by authenticated users"
    on public.profiles for select
    to authenticated
    using (true);

create policy "Users can update own profile"
    on public.profiles for update
    to authenticated
    using (auth.uid() = id);

-- 2. Workspaces Table
create table if not exists public.workspaces (
    id uuid default gen_random_uuid() primary key,
    name text not null,
    slug text not null unique,
    description text,
    avatar_url text,
    owner_id uuid references public.profiles(id) on delete cascade not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.workspaces enable row level security;

-- 3. Workspace Members Table
create table if not exists public.workspace_members (
    id uuid default gen_random_uuid() primary key,
    workspace_id uuid references public.workspaces(id) on delete cascade not null,
    user_id uuid references public.profiles(id) on delete cascade not null,
    role text check (role in ('owner', 'admin', 'member', 'viewer', 'guest')) default 'member' not null,
    joined_at timestamp with time zone default timezone('utc'::text, now()) not null,
    unique (workspace_id, user_id)
);

alter table public.workspace_members enable row level security;

create policy "Members can view their workspaces"
    on public.workspaces for select
    to authenticated
    using (
        exists (
            select 1 from public.workspace_members
            where workspace_members.workspace_id = workspaces.id
            and workspace_members.user_id = auth.uid()
        )
    );

create policy "Authenticated users can create workspaces"
    on public.workspaces for insert
    to authenticated
    with check (auth.uid() = owner_id);

create policy "Workspace owners can update workspaces"
    on public.workspaces for update
    to authenticated
    using (
        exists (
            select 1 from public.workspace_members wm
            where wm.workspace_id = workspaces.id
            and wm.user_id = auth.uid()
            and wm.role in ('owner', 'admin')
        )
    );

create policy "Workspace members can view member lists"
    on public.workspace_members for select
    to authenticated
    using (
        exists (
            select 1 from public.workspace_members wm
            where wm.workspace_id = workspace_members.workspace_id
            and wm.user_id = auth.uid()
        )
    );

create policy "Workspace owners and admins can manage members"
    on public.workspace_members for insert
    to authenticated
    with check (
        exists (
            select 1 from public.workspace_members wm
            where wm.workspace_id = workspace_members.workspace_id
            and wm.user_id = auth.uid()
            and wm.role in ('owner', 'admin')
        ) or (auth.uid() = user_id) -- allow owner auto-join
    );

create policy "Workspace owners and admins can update member roles"
    on public.workspace_members for update
    to authenticated
    using (
        exists (
            select 1 from public.workspace_members wm
            where wm.workspace_id = workspace_members.workspace_id
            and wm.user_id = auth.uid()
            and wm.role in ('owner', 'admin')
        )
    );

create policy "Workspace owners and admins can remove members"
    on public.workspace_members for delete
    to authenticated
    using (
        exists (
            select 1 from public.workspace_members wm
            where wm.workspace_id = workspace_members.workspace_id
            and wm.user_id = auth.uid()
            and wm.role in ('owner', 'admin')
        ) or (auth.uid() = user_id) -- allow self leave
    );

-- 4. Workspace Invitations Table
create table if not exists public.workspace_invitations (
    id uuid default gen_random_uuid() primary key,
    workspace_id uuid references public.workspaces(id) on delete cascade not null,
    email text not null,
    role text check (role in ('admin', 'member', 'viewer')) default 'member' not null,
    token text not null unique,
    invited_by uuid references public.profiles(id) on delete set null,
    expires_at timestamp with time zone default (now() + interval '7 days') not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.workspace_invitations enable row level security;

create policy "Workspace members can view invitations"
    on public.workspace_invitations for select
    to authenticated
    using (
        exists (
            select 1 from public.workspace_members wm
            where wm.workspace_id = workspace_invitations.workspace_id
            and wm.user_id = auth.uid()
        )
    );

create policy "Admins can create invitations"
    on public.workspace_invitations for insert
    to authenticated
    with check (
        exists (
            select 1 from public.workspace_members wm
            where wm.workspace_id = workspace_invitations.workspace_id
            and wm.user_id = auth.uid()
            and wm.role in ('owner', 'admin')
        )
    );

-- 5. Projects Table
create table if not exists public.projects (
    id uuid default gen_random_uuid() primary key,
    workspace_id uuid references public.workspaces(id) on delete cascade not null,
    name text not null,
    description text,
    color text default '#6366F1' not null,
    status text check (status in ('active', 'archived', 'completed')) default 'active' not null,
    creator_id uuid references public.profiles(id) on delete set null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.projects enable row level security;

create policy "Workspace members can view projects"
    on public.projects for select
    to authenticated
    using (
        exists (
            select 1 from public.workspace_members wm
            where wm.workspace_id = projects.workspace_id
            and wm.user_id = auth.uid()
        )
    );

create policy "Workspace members can insert projects"
    on public.projects for insert
    to authenticated
    with check (
        exists (
            select 1 from public.workspace_members wm
            where wm.workspace_id = projects.workspace_id
            and wm.user_id = auth.uid()
            and wm.role in ('owner', 'admin', 'member')
        )
    );

create policy "Workspace members can update projects"
    on public.projects for update
    to authenticated
    using (
        exists (
            select 1 from public.workspace_members wm
            where wm.workspace_id = projects.workspace_id
            and wm.user_id = auth.uid()
            and wm.role in ('owner', 'admin', 'member')
        )
    );

-- 6. Task Labels Table
create table if not exists public.task_labels (
    id uuid default gen_random_uuid() primary key,
    workspace_id uuid references public.workspaces(id) on delete cascade not null,
    name text not null,
    color_hex text default '#6366F1' not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.task_labels enable row level security;

create policy "Workspace members can view and manage labels"
    on public.task_labels for all
    to authenticated
    using (
        exists (
            select 1 from public.workspace_members wm
            where wm.workspace_id = task_labels.workspace_id
            and wm.user_id = auth.uid()
        )
    );

-- 7. Tasks Table
create table if not exists public.tasks (
    id uuid default gen_random_uuid() primary key,
    project_id uuid references public.projects(id) on delete cascade not null,
    title text not null,
    description text default '',
    status text check (status in ('TODO', 'IN_PROGRESS', 'IN_REVIEW', 'DONE')) default 'TODO' not null,
    priority text check (priority in ('LOW', 'MEDIUM', 'HIGH', 'URGENT')) default 'MEDIUM' not null,
    assignee_id uuid references public.profiles(id) on delete set null,
    creator_id uuid references public.profiles(id) on delete set null,
    due_date timestamp with time zone,
    position double precision default 1000.0 not null,
    version integer default 1 not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.tasks enable row level security;

create policy "Project members can view tasks"
    on public.tasks for select
    to authenticated
    using (
        exists (
            select 1 from public.projects p
            join public.workspace_members wm on wm.workspace_id = p.workspace_id
            where p.id = tasks.project_id
            and wm.user_id = auth.uid()
        )
    );

create policy "Project members can insert tasks"
    on public.tasks for insert
    to authenticated
    with check (
        exists (
            select 1 from public.projects p
            join public.workspace_members wm on wm.workspace_id = p.workspace_id
            where p.id = tasks.project_id
            and wm.user_id = auth.uid()
            and wm.role in ('owner', 'admin', 'member')
        )
    );

create policy "Project members can update tasks"
    on public.tasks for update
    to authenticated
    using (
        exists (
            select 1 from public.projects p
            join public.workspace_members wm on wm.workspace_id = p.workspace_id
            where p.id = tasks.project_id
            and wm.user_id = auth.uid()
        )
    );

create policy "Project members can delete tasks"
    on public.tasks for delete
    to authenticated
    using (
        exists (
            select 1 from public.projects p
            join public.workspace_members wm on wm.workspace_id = p.workspace_id
            where p.id = tasks.project_id
            and wm.user_id = auth.uid()
            and wm.role in ('owner', 'admin', 'member')
        )
    );

-- 8. Subtasks / Checklist Items Table
create table if not exists public.task_subtasks (
    id uuid default gen_random_uuid() primary key,
    task_id uuid references public.tasks(id) on delete cascade not null,
    title text not null,
    is_completed boolean default false not null,
    position double precision default 1000.0 not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.task_subtasks enable row level security;

create policy "Project members can manage subtasks"
    on public.task_subtasks for all
    to authenticated
    using (
        exists (
            select 1 from public.tasks t
            join public.projects p on p.id = t.project_id
            join public.workspace_members wm on wm.workspace_id = p.workspace_id
            where t.id = task_subtasks.task_id
            and wm.user_id = auth.uid()
        )
    );

-- 9. Task Comments Table
create table if not exists public.task_comments (
    id uuid default gen_random_uuid() primary key,
    task_id uuid references public.tasks(id) on delete cascade not null,
    author_id uuid references public.profiles(id) on delete cascade not null,
    content text not null,
    reply_to_id uuid references public.task_comments(id) on delete set null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.task_comments enable row level security;

create policy "Project members can view comments"
    on public.task_comments for select
    to authenticated
    using (
        exists (
            select 1 from public.tasks t
            join public.projects p on p.id = t.project_id
            join public.workspace_members wm on wm.workspace_id = p.workspace_id
            where t.id = task_comments.task_id
            and wm.user_id = auth.uid()
        )
    );

create policy "Project members can insert comments"
    on public.task_comments for insert
    to authenticated
    with check (
        exists (
            select 1 from public.tasks t
            join public.projects p on p.id = t.project_id
            join public.workspace_members wm on wm.workspace_id = p.workspace_id
            where t.id = task_comments.task_id
            and wm.user_id = auth.uid()
        )
    );

-- 10. Task Attachments Table
create table if not exists public.task_attachments (
    id uuid default gen_random_uuid() primary key,
    task_id uuid references public.tasks(id) on delete cascade not null,
    file_name text not null,
    file_url text not null,
    file_size_bytes bigint default 0 not null,
    file_type text default 'file' not null,
    uploaded_by uuid references public.profiles(id) on delete set null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.task_attachments enable row level security;

create policy "Project members can view and add attachments"
    on public.task_attachments for all
    to authenticated
    using (
        exists (
            select 1 from public.tasks t
            join public.projects p on p.id = t.project_id
            join public.workspace_members wm on wm.workspace_id = p.workspace_id
            where t.id = task_attachments.task_id
            and wm.user_id = auth.uid()
        )
    );

-- 11. Task Time Entries Table
create table if not exists public.task_time_entries (
    id uuid default gen_random_uuid() primary key,
    task_id uuid references public.tasks(id) on delete cascade not null,
    user_id uuid references public.profiles(id) on delete cascade not null,
    duration_seconds integer not null,
    started_at timestamp with time zone not null,
    ended_at timestamp with time zone,
    note text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.task_time_entries enable row level security;

create policy "Project members can view and add time entries"
    on public.task_time_entries for all
    to authenticated
    using (
        exists (
            select 1 from public.tasks t
            join public.projects p on p.id = t.project_id
            join public.workspace_members wm on wm.workspace_id = p.workspace_id
            where t.id = task_time_entries.task_id
            and wm.user_id = auth.uid()
        )
    );

-- 12. Task Activity Events (Audit Stream)
create table if not exists public.activity_events (
    id uuid default gen_random_uuid() primary key,
    project_id uuid references public.projects(id) on delete cascade not null,
    task_id uuid references public.tasks(id) on delete set null,
    actor_id uuid references public.profiles(id) on delete set null,
    action_type text not null,
    summary text not null,
    metadata jsonb default '{}'::jsonb,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.activity_events enable row level security;

create policy "Project members can view activity"
    on public.activity_events for select
    to authenticated
    using (
        exists (
            select 1 from public.projects p
            join public.workspace_members wm on wm.workspace_id = p.workspace_id
            where p.id = activity_events.project_id
            and wm.user_id = auth.uid()
        )
    );

-- 13. Notifications Table
create table if not exists public.notifications (
    id uuid default gen_random_uuid() primary key,
    user_id uuid references public.profiles(id) on delete cascade not null,
    workspace_id uuid references public.workspaces(id) on delete cascade not null,
    title text not null,
    body text not null,
    type text not null, -- 'task_assigned', 'comment_mention', 'due_date', 'workspace_invite'
    entity_id uuid, -- target taskId or projectId
    is_read boolean default false not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.notifications enable row level security;

create policy "Users can view and update own notifications"
    on public.notifications for all
    to authenticated
    using (auth.uid() = user_id);

-- 14. Realtime Replication Publications
alter publication supabase_realtime add table public.tasks;
alter publication supabase_realtime add table public.projects;
alter publication supabase_realtime add table public.workspace_members;
alter publication supabase_realtime add table public.task_comments;
alter publication supabase_realtime add table public.activity_events;
alter publication supabase_realtime add table public.notifications;

-- Auto create profile on auth signup trigger
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, full_name, avatar_url)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'avatar_url', null)
  );
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
