-- Import vestavěných rébusů do účtu autora: seed_key = původní id ("seed-..."),
-- aby se zachoval postup hráčů. Vysvětlení může být u importovaných zatím prázdné.
alter table public.puzzles add column if not exists seed_key text unique;

alter table public.puzzles alter column explanation drop not null;
alter table public.puzzles drop constraint if exists puzzles_explanation_check;
alter table public.puzzles
  add constraint puzzles_explanation_check
  check (explanation is null or char_length(btrim(explanation)) > 0);
