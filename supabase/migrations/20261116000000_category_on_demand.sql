-- Sady „jen na vyžádání“: rébusy se nemíchají do výběru „Všechny sady“,
-- hrají se až po výběru sady (filmy, táborové apod.).

alter table public.puzzle_categories
  add column if not exists on_demand boolean not null default false;

-- Táborové: sada už je založená správcem, id neznáme, proto podle názvu.
update public.puzzle_categories set on_demand = true
where lower(label) like '%tábor%' or lower(label) like '%tabor%';
