-- Nový druh slova "cizí jazyk" (foreign): řešení vzniká z cizích (např. anglických) slov.
alter table public.puzzles drop constraint if exists puzzles_word_type_check;
alter table public.puzzles
  add constraint puzzles_word_type_check
  check (word_type in ('verb', 'noun', 'adjective', 'city', 'plural', 'foreign', 'other'));
