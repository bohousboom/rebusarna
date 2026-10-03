-- Moderace: správce smí upravit/smazat jakýkoli rébus a hráči mohou rébusy nahlásit.

-- Správce upravuje a maže cizí rébusy (vlastník dál své).
drop policy if exists "puzzles: úprava správcem" on public.puzzles;
create policy "puzzles: úprava správcem" on public.puzzles
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "puzzles: mazání správcem" on public.puzzles;
create policy "puzzles: mazání správcem" on public.puzzles
  for delete to authenticated using (public.is_admin());

-- ... a odstraní i jejich obrázky z úložiště.
drop policy if exists "obrázky: mazání správcem" on storage.objects;
create policy "obrázky: mazání správcem" on storage.objects
  for delete to authenticated
  using (bucket_id = 'puzzle-images' and public.is_admin());

-- Nahlášení: jeden hlas na hráče a rébus; čte a maže jen správce.
create table if not exists public.puzzle_reports (
  id          uuid primary key default gen_random_uuid(),
  puzzle_id   text not null,
  reporter_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  reason      text not null check (reason in ('adult', 'wrong', 'offensive', 'other')),
  note        text check (note is null or char_length(note) <= 500),
  created_at  timestamptz not null default now(),
  unique (puzzle_id, reporter_id)
);

alter table public.puzzle_reports enable row level security;

drop policy if exists "reports: vkládá hráč za sebe" on public.puzzle_reports;
create policy "reports: vkládá hráč za sebe" on public.puzzle_reports
  for insert to authenticated with check (reporter_id = auth.uid());

drop policy if exists "reports: čte správce" on public.puzzle_reports;
create policy "reports: čte správce" on public.puzzle_reports
  for select to authenticated using (public.is_admin());

drop policy if exists "reports: maže správce" on public.puzzle_reports;
create policy "reports: maže správce" on public.puzzle_reports
  for delete to authenticated using (public.is_admin());
