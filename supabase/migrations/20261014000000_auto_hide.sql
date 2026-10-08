-- Automatické skrytí: rébus nahlášený alespoň 3 různými hráči se sám skryje, dokud
-- ho správce neposoudí. Skrytý rébus vidí jen jeho autor a správce.

alter table public.puzzles add column if not exists hidden boolean not null default false;

-- is_admin() se vyhodnocuje i v čtecí politice, tedy i pro nepřihlášené (vrací false).
grant execute on function public.is_admin() to anon;

drop policy if exists "puzzles: čtení pro všechny" on public.puzzles;
drop policy if exists "puzzles: čtení nezkrytých" on public.puzzles;
create policy "puzzles: čtení nezkrytých" on public.puzzles
  for select using (not hidden or owner_id = auth.uid() or public.is_admin());

-- Nahlášení: po třetím hlasu se rébus skryje. Vestavěné rébusy (seed_key) se neskrývají,
-- ty spravuje správce ručně.
create or replace function public.hide_when_reported()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if (select count(*) from public.puzzle_reports where puzzle_id = new.puzzle_id) >= 3 then
    update public.puzzles set hidden = true
    where id::text = new.puzzle_id and seed_key is null;
  end if;
  return new;
end;
$$;

drop trigger if exists puzzle_reports_hide on public.puzzle_reports;
create trigger puzzle_reports_hide
  after insert on public.puzzle_reports
  for each row execute function public.hide_when_reported();

-- Příznak `hidden` mění jen správce (nebo tento trigger výše); autor si skrytý rébus
-- nemůže sám odkrýt.
create or replace function public.guard_hidden()
returns trigger
language plpgsql
as $$
begin
  if new.hidden is distinct from old.hidden
     and pg_trigger_depth() = 1
     and not public.is_admin() then
    new.hidden := old.hidden;
  end if;
  return new;
end;
$$;

drop trigger if exists puzzles_guard_hidden on public.puzzles;
create trigger puzzles_guard_hidden
  before update on public.puzzles
  for each row execute function public.guard_hidden();

-- Zamítnutí nahlášení (správce): smaže hlášení a rébus zase zobrazí.
create or replace function public.dismiss_reports(p_puzzle_id text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Jen správce';
  end if;
  delete from public.puzzle_reports where puzzle_id = p_puzzle_id;
  update public.puzzles set hidden = false
  where id::text = p_puzzle_id or seed_key = p_puzzle_id;
end;
$$;

revoke all on function public.dismiss_reports(text) from public;
grant execute on function public.dismiss_reports(text) to authenticated;
