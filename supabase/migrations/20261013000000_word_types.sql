-- Rébus může mít více druhů slova. word_type zůstává (hlavní druh, kvůli
-- starším verzím aplikace), word_types je celý seznam.
alter table public.puzzles add column if not exists word_types text[];
update public.puzzles set word_types = array[word_type] where word_types is null;
