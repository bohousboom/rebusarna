-- Značka 18+: takové rébusy se hráčům ukážou jen po zapnutí v aplikaci.
alter table public.puzzles add column if not exists is_adult boolean not null default false;
