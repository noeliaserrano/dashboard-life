-- Mi Pared de Pósits · base de datos para compartir la casa entre dos personas.
-- Pega todo este archivo en Supabase → SQL Editor → New query → Run. Solo hace falta una vez.
--
-- Privacidad:
--  * Todo lo que guarda la app llega ya CIFRADO desde el móvil con la "clave de la casa".
--    Aquí solo se guarda texto ilegible (columna data). Sin esa clave no se puede leer.
--  * Las reglas de abajo (Row Level Security) hacen que cada persona solo pueda tocar
--    lo de su casa: lo común de los dos y SU parte personal. Lo personal del otro, nunca.

-- Casas: una por pareja. salt sirve para derivar la clave de cifrado (no es secreto).
create table if not exists public.households (
  id uuid primary key default gen_random_uuid(),
  salt text not null,
  invite_code text unique not null,
  created_at timestamptz not null default now()
);

-- Personas de cada casa (máximo dos). role A = quien crea la casa, B = quien se une.
create table if not exists public.members (
  household_id uuid not null references public.households(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('A', 'B')),
  name text,
  primary key (household_id, user_id)
);

-- Datos cifrados. id = 'shared:<casa>' para lo común, 'personal:<usuario>' para lo de cada uno.
create table if not exists public.vault (
  id text primary key,
  household_id uuid not null references public.households(id) on delete cascade,
  owner uuid references auth.users(id) on delete cascade,
  data text not null,
  iv text not null,
  updated_at timestamptz not null default now()
);

alter table public.households enable row level security;
alter table public.members enable row level security;
alter table public.vault enable row level security;

-- ¿Soy miembro de esta casa?
create or replace function public.is_member(h uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.members where household_id = h and user_id = auth.uid());
$$;

drop policy if exists "ver mi casa" on public.households;
create policy "ver mi casa" on public.households for select using (public.is_member(id));

drop policy if exists "ver miembros de mi casa" on public.members;
create policy "ver miembros de mi casa" on public.members for select using (public.is_member(household_id));
drop policy if exists "cambiar mi nombre" on public.members;
create policy "cambiar mi nombre" on public.members for update using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Lo común (owner vacío) lo ven los dos; lo personal solo su dueño.
drop policy if exists "leer datos" on public.vault;
create policy "leer datos" on public.vault for select
  using (public.is_member(household_id) and (owner is null or owner = auth.uid()));
drop policy if exists "crear datos" on public.vault;
create policy "crear datos" on public.vault for insert
  with check (public.is_member(household_id) and (owner is null or owner = auth.uid())
    and id = case when owner is null then 'shared:' || household_id::text else 'personal:' || auth.uid()::text end);
drop policy if exists "guardar datos" on public.vault;
create policy "guardar datos" on public.vault for update
  using (public.is_member(household_id) and (owner is null or owner = auth.uid()))
  with check (public.is_member(household_id) and (owner is null or owner = auth.uid()));

-- Crear una casa nueva (quien la crea es A). Devuelve el código para invitar a la pareja.
create or replace function public.create_household(p_name text, p_salt text)
returns table (household_id uuid, invite_code text)
language plpgsql security definer set search_path = public as $$
declare h uuid; code text;
begin
  if auth.uid() is null then raise exception 'Hay que iniciar sesión'; end if;
  if exists (select 1 from public.members where user_id = auth.uid()) then raise exception 'Ya perteneces a una casa'; end if;
  code := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
  insert into public.households (salt, invite_code) values (p_salt, code) returning id into h;
  insert into public.members (household_id, user_id, role, name) values (h, auth.uid(), 'A', p_name);
  return query select h, code;
end $$;

-- Unirse a una casa con el código (quien se une es B). Máximo dos personas.
create or replace function public.join_household(p_code text, p_name text)
returns uuid
language plpgsql security definer set search_path = public as $$
declare h uuid;
begin
  if auth.uid() is null then raise exception 'Hay que iniciar sesión'; end if;
  if exists (select 1 from public.members where user_id = auth.uid()) then raise exception 'Ya perteneces a una casa'; end if;
  select id into h from public.households where invite_code = upper(trim(p_code));
  if h is null then raise exception 'Código no válido'; end if;
  if (select count(*) from public.members where household_id = h) >= 2 then raise exception 'Esta casa ya tiene dos personas'; end if;
  insert into public.members (household_id, user_id, role, name) values (h, auth.uid(), 'B', p_name);
  return h;
end $$;

revoke all on function public.create_household(text, text) from public, anon;
revoke all on function public.join_household(text, text) from public, anon;
grant execute on function public.create_household(text, text) to authenticated;
grant execute on function public.join_household(text, text) to authenticated;
grant execute on function public.is_member(uuid) to authenticated;
