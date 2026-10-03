-- Rébusárna: základní schéma. Spustit v Supabase (SQL Editor) nebo přes GitHub integraci.

-- ---------------------------------------------------------------- rébusy
create table public.puzzles (
  id            uuid primary key default gen_random_uuid(),
  owner_id      uuid not null default auth.uid() references auth.users (id) on delete cascade,
  image_path    text not null,              -- cesta v úložišti puzzle-images
  solution      text not null check (char_length(btrim(solution)) > 0),
  meaning       text,
  explanation   text not null check (char_length(btrim(explanation)) > 0),
  word_type     text not null default 'noun' check (word_type in ('verb', 'noun', 'adjective', 'other')),
  difficulty    int  not null default 1 check (difficulty between 1 and 3),
  author_name   text not null default 'Anonym',
  created_at    timestamptz not null default now(),
  rating_sum    int not null default 0,
  rating_count  int not null default 0
);

create index puzzles_owner_idx on public.puzzles (owner_id);
create index puzzles_created_idx on public.puzzles (created_at desc);

alter table public.puzzles enable row level security;

-- Číst smí každý (i nepřihlášený); měnit jen vlastník.
create policy "puzzles: čtení pro všechny" on public.puzzles
  for select using (true);
create policy "puzzles: vkládá přihlášený za sebe" on public.puzzles
  for insert to authenticated with check (owner_id = auth.uid());
create policy "puzzles: úprava vlastníkem" on public.puzzles
  for update to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "puzzles: mazání vlastníkem" on public.puzzles
  for delete to authenticated using (owner_id = auth.uid());

-- ---------------------------------------------------------------- postup hráče
-- puzzle_id je text: vestavěné rébusy mají id "seed-...", uživatelské uuid.
create table public.solved (
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  puzzle_id  text not null,
  solved_at  timestamptz not null default now(),
  primary key (user_id, puzzle_id)
);

create table public.favorites (
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  puzzle_id  text not null,
  created_at timestamptz not null default now(),
  primary key (user_id, puzzle_id)
);

create table public.profiles (
  user_id      uuid primary key default auth.uid() references auth.users (id) on delete cascade,
  display_name text,
  streak       int not null default 0
);

alter table public.solved enable row level security;
alter table public.favorites enable row level security;
alter table public.profiles enable row level security;

create policy "solved: jen vlastní" on public.solved
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "favorites: jen vlastní" on public.favorites
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "profiles: jen vlastní" on public.profiles
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------- úložiště obrázků
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('puzzle-images', 'puzzle-images', true, 1048576,
        array['image/webp', 'image/jpeg', 'image/png'])
on conflict (id) do nothing;

-- Čtení je veřejné (bucket je public). Nahrávat smí přihlášený jen do složky se svým user id.
create policy "obrázky: nahrávání do vlastní složky" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'puzzle-images' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "obrázky: mazání z vlastní složky" on storage.objects
  for delete to authenticated
  using (bucket_id = 'puzzle-images' and (storage.foldername(name))[1] = auth.uid()::text);
