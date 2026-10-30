-- Denní série: poslední den, kdy hráč uhodl rébus (série = dny v řadě).
alter table public.profiles add column if not exists last_solved_day date;
-- Dosavadní "série" počítala uhodnuté rébusy, ne dny; začíná se znovu.
update public.profiles set streak = 0;

-- Autor vidí, kdo olajkoval jeho rébusy (jméno z Google profilu). Čte se jen přes
-- tuto funkci, tabulka puzzle_likes zůstává čitelná jen pro vlastní hlasy.
create or replace function public.my_puzzle_likes()
returns table (puzzle_id text, liker_name text, created_at timestamptz)
language sql
stable
security definer
set search_path = public
as $$
  select l.puzzle_id,
         coalesce(nullif(trim(u.raw_user_meta_data ->> 'full_name'), ''),
                  nullif(trim(u.raw_user_meta_data ->> 'name'), ''),
                  'Hráč') as liker_name,
         l.created_at
  from public.puzzle_likes l
  join public.puzzles p on p.id::text = l.puzzle_id or p.seed_key = l.puzzle_id
  left join auth.users u on u.id = l.user_id
  where p.owner_id = auth.uid()
  order by l.created_at desc;
$$;

revoke all on function public.my_puzzle_likes() from public, anon;
grant execute on function public.my_puzzle_likes() to authenticated;
