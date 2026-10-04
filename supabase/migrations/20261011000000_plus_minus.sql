-- Štítek ±: nově ho nastavuje autor rébusu (dřív se odvozoval z řešení).
alter table public.puzzles add column if not exists is_plus_minus boolean not null default false;

-- Stávající rébusy: zachovat dosavadní chování (řešení bez znaků s čárkou).
update public.puzzles
   set is_plus_minus = solution !~* '[áéíóúý]';
