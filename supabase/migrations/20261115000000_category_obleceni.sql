-- Nová sada „Oblečení“ (vyčleněná z „Domov a věci“); „Činnosti (slovesa)“ se zrušila,
-- slovesa se poznají podle štítku na kartě a patří do „Ostatní“.

insert into public.puzzle_categories (id, label, icon_name, sort)
values ('obleceni', 'Oblečení', 'checkroom', 55)
on conflict (id) do nothing;

update public.puzzles set category = 'obleceni'
where category = 'domov'
  and lower(btrim(solution)) in ('hábit', 'kabelka', 'kapesník', 'kravata', 'kulich',
    'mikina', 'návlek', 'pantofle', 'plášť', 'tepláky', 'čepice');

update public.puzzles set category = 'other' where category = 'cinnosti';
delete from public.puzzle_categories where id = 'cinnosti';
