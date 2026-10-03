-- Trvale smazané vestavěné rébusy: aplikace je nezobrazuje a import je přeskočí.
-- Skript lze bezpečně spustit opakovaně.
create table if not exists public.deleted_seeds (
  seed_key   text primary key,
  deleted_at timestamptz not null default now()
);

alter table public.deleted_seeds enable row level security;

drop policy if exists "deleted_seeds: čtení pro všechny" on public.deleted_seeds;
create policy "deleted_seeds: čtení pro všechny" on public.deleted_seeds
  for select using (true);

drop policy if exists "deleted_seeds: vkládá správce" on public.deleted_seeds;
create policy "deleted_seeds: vkládá správce" on public.deleted_seeds
  for insert to authenticated with check (public.is_admin());

drop policy if exists "deleted_seeds: maže správce" on public.deleted_seeds;
create policy "deleted_seeds: maže správce" on public.deleted_seeds
  for delete to authenticated using (public.is_admin());
