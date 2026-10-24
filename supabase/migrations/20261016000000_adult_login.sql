-- Rébusy 18+ vidí jen přihlášení (plus autor a správce). Nepřihlášenému je databáze nevrátí.
-- Pozn.: soubory v úložišti obrázků jsou veřejné, chrání se tedy jen seznam rébusů.

drop policy if exists "puzzles: čtení nezkrytých" on public.puzzles;
create policy "puzzles: čtení nezkrytých" on public.puzzles
  for select using (
    (not hidden and (not is_adult or auth.uid() is not null))
    or owner_id = auth.uid()
    or public.is_admin()
  );
