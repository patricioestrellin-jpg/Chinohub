-- CHINOINFIERNO · KEY MANAGER V1
-- Ejecuta este archivo completo UNA VEZ en Supabase > SQL Editor.
-- Seguridad: el código secreto NUNCA aparece en el listado público.

create extension if not exists pgcrypto;

create table if not exists public.chino_admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);

create table if not exists public.chino_keys (
  id uuid primary key default gen_random_uuid(),
  plan text not null check (length(trim(plan)) between 1 and 80),
  code text not null unique check (length(trim(code)) between 1 and 300),
  status text not null default 'available' check (status in ('available', 'full', 'reserved')),
  claimed_by uuid references auth.users(id) on delete set null,
  claimed_at timestamptz,
  created_at timestamptz not null default now(),
  constraint claimed_keys_are_full check (claimed_by is null or status = 'full')
);

-- La misma cuenta solo puede reclamar una key.
create unique index if not exists chino_one_claim_per_account
on public.chino_keys (claimed_by) where claimed_by is not null;
create index if not exists chino_keys_created on public.chino_keys (created_at desc);

alter table public.chino_admins enable row level security;
alter table public.chino_keys enable row level security;

create or replace function public.chino_is_admin()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.chino_admins a where a.user_id = auth.uid()
  );
$$;

-- Los dueños pueden consultar sus keys. El admin tiene acceso a todo.
drop policy if exists "chino_admin_can_manage" on public.chino_keys;
create policy "chino_admin_can_manage"
on public.chino_keys for all to authenticated
using (public.chino_is_admin())
with check (public.chino_is_admin());

drop policy if exists "chino_owner_can_read_claimed" on public.chino_keys;
create policy "chino_owner_can_read_claimed"
on public.chino_keys for select to authenticated
using (claimed_by = auth.uid());

-- Inventario público SIN el código secreto y SIN datos personales.
create or replace function public.chino_inventory()
returns table (id uuid, plan text, status text, created_at timestamptz)
language sql stable security definer
set search_path = ''
as $$
  select k.id, k.plan, k.status, k.created_at
  from public.chino_keys k
  order by k.created_at desc, k.id;
$$;

-- Reclamo atómico: dos usuarios NO pueden recibir la misma key.
create or replace function public.chino_claim(p_key_id uuid)
returns table (id uuid, plan text, code text, status text)
language plpgsql security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'LOGIN_REQUIRED';
  end if;

  if exists (select 1 from public.chino_keys k where k.claimed_by = auth.uid()) then
    raise exception 'ALREADY_CLAIMED';
  end if;

  return query
  update public.chino_keys as k
     set status = 'full', claimed_by = auth.uid(), claimed_at = now()
   where k.id = p_key_id and k.status = 'available'
  returning k.id, k.plan, k.code, k.status;

  if not found then
    raise exception 'NOT_AVAILABLE';
  end if;
exception
  when unique_violation then
    raise exception 'ALREADY_CLAIMED';
end;
$$;

-- Permisos mínimos de las funciones.
revoke all on function public.chino_is_admin() from public, anon;
grant execute on function public.chino_is_admin() to authenticated;
revoke all on function public.chino_inventory() from public, anon, authenticated;
grant execute on function public.chino_inventory() to anon, authenticated;
revoke all on function public.chino_claim(uuid) from public, anon;
grant execute on function public.chino_claim(uuid) to authenticated;

-- Se necesita acceso de tabla para las operaciones del admin y el SELECT propio;
-- RLS sigue bloqueando todas las escrituras a usuarios normales.
revoke all on table public.chino_keys from anon;
grant select, insert, update, delete on table public.chino_keys to authenticated;
revoke all on table public.chino_admins from anon, authenticated;

-- IMPORTANTE: REGISTRAR AL ADMIN
-- 1) Abre la web, inicia sesión con TU correo y sigue el enlace que te llegue.
-- 2) Vuelve a SQL Editor y ejecuta ESTO con tu correo verdadero (sin --):
-- insert into public.chino_admins (user_id)
-- select id from auth.users where lower(email) = lower('TUCORREO@EJEMPLO.COM')
-- on conflict do nothing;
-- 3) Actualiza la página. Aparecerá el panel privado.
-- No agregues amigos como administradores salvo que realmente quieras darles control.
