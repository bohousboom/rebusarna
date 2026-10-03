-- Obtížnost podle hráčů: každý přihlášený hráč zapíše u rébusu jen jeden výsledek
-- (první pokus). Skóre = špatné tipy (max 5) + 2 za nápovědu + 6 za ukázané řešení.
create table if not exists public.puzzle_results (
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  puzzle_id  text not null,
  wrong      int  not null default 0 check (wrong between 0 and 1000),
  hints      int  not null default 0 check (hints between 0 and 2),
  revealed   boolean not null default false,
  score      int generated always as (
               least(wrong, 5) + 2 * hints + case when revealed then 6 else 0 end
             ) stored,
  created_at timestamptz not null default now(),
  primary key (user_id, puzzle_id)
);

alter table public.puzzle_results enable row level security;

drop policy if exists "results: vkládá hráč za sebe" on public.puzzle_results;
create policy "results: vkládá hráč za sebe" on public.puzzle_results
  for insert to authenticated with check (user_id = auth.uid());

-- Agregát bez jednotlivých výsledků (pohled běží s právy vlastníka, tabulku nikdo nečte).
create or replace view public.puzzle_difficulty as
  select puzzle_id, count(*)::int as n, avg(score)::float8 as avg_score
  from public.puzzle_results
  group by puzzle_id;

grant select on public.puzzle_difficulty to anon, authenticated;
