-- Ohlas rébusů: hráč dá rébusu "líbí se mi" (jeden hlas na hráče a rébus). Počet se
-- ukládá do puzzles.rating_count (rating_sum se drží stejný), autor ho vidí u svých karet.

create table if not exists public.puzzle_likes (
  puzzle_id  text not null,
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (puzzle_id, user_id)
);

alter table public.puzzle_likes enable row level security;

-- Každý vidí a mění jen své hlasy; počty čte každý přímo z puzzles.
drop policy if exists "likes: čtení vlastních" on public.puzzle_likes;
create policy "likes: čtení vlastních" on public.puzzle_likes
  for select to authenticated using (user_id = auth.uid());

drop policy if exists "likes: vkládá hráč za sebe" on public.puzzle_likes;
create policy "likes: vkládá hráč za sebe" on public.puzzle_likes
  for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "likes: maže hráč své" on public.puzzle_likes;
create policy "likes: maže hráč své" on public.puzzle_likes
  for delete to authenticated using (user_id = auth.uid());

-- Udržuje počet hlasů u rébusu (id i seed_key, jako u nahlášení).
create or replace function public.count_likes()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  pid text := coalesce(new.puzzle_id, old.puzzle_id);
  n   int;
begin
  select count(*) into n from public.puzzle_likes where puzzle_id = pid;
  update public.puzzles set rating_count = n, rating_sum = n
  where id::text = pid or seed_key = pid;
  return null;
end;
$$;

drop trigger if exists puzzle_likes_count on public.puzzle_likes;
create trigger puzzle_likes_count
  after insert or delete on public.puzzle_likes
  for each row execute function public.count_likes();

-- rating_* smí měnit jen tento trigger (pg_trigger_depth > 1), ne autor přes update.
create or replace function public.guard_rating()
returns trigger
language plpgsql
as $$
begin
  if pg_trigger_depth() = 1 and (new.rating_count is distinct from old.rating_count
                              or new.rating_sum is distinct from old.rating_sum) then
    new.rating_count := old.rating_count;
    new.rating_sum := old.rating_sum;
  end if;
  return new;
end;
$$;

drop trigger if exists puzzles_guard_rating on public.puzzles;
create trigger puzzles_guard_rating
  before update on public.puzzles
  for each row execute function public.guard_rating();
