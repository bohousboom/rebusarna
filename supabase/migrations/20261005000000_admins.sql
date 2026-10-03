-- Import vestavěných rébusů (seed_key) smí provést jen správce. Běžní uživatelé
-- dál nahrávají vlastní rébusy bez omezení.

create table if not exists public.app_admins (
  user_id uuid primary key references auth.users (id) on delete cascade
);

-- RLS bez politik = klienti tabulku nevidí ani nemění (spravuje se jen v SQL Editoru).
alter table public.app_admins enable row level security;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.app_admins where user_id = auth.uid());
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

drop policy if exists "puzzles: vkládá přihlášený za sebe" on public.puzzles;
create policy "puzzles: vkládá přihlášený za sebe" on public.puzzles
  for insert to authenticated
  with check (owner_id = auth.uid() and (seed_key is null or public.is_admin()));

-- Po prvním přihlášení se přidej jako správce (v SQL Editoru, jednou).
-- Nahraď e-mail tím, kterým se přihlašuješ přes Google:
--
--   insert into public.app_admins (user_id)
--   select id from auth.users where email = 'tvuj@email.cz'
--   on conflict do nothing;
