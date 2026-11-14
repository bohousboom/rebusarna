-- Sady (témata) rébusů: výběr sady ve hře, nápověda a štítek po vyřešení.
-- Seznam sad je v tabulce; čte ho každý, zakládat a přejmenovat smí jen správce.

create table if not exists public.puzzle_categories (
  id         text primary key check (id ~ '^[a-z0-9_]+$'),
  label      text not null check (char_length(btrim(label)) between 1 and 40),
  icon_name  text,
  sort       int  not null default 500
);
create unique index if not exists puzzle_categories_label_idx
  on public.puzzle_categories (lower(btrim(label)));

alter table public.puzzle_categories enable row level security;

drop policy if exists "puzzle_categories: čtení pro všechny" on public.puzzle_categories;
create policy "puzzle_categories: čtení pro všechny" on public.puzzle_categories
  for select using (true);

drop policy if exists "puzzle_categories: vkládá správce" on public.puzzle_categories;
create policy "puzzle_categories: vkládá správce" on public.puzzle_categories
  for insert to authenticated with check (public.is_admin());

drop policy if exists "puzzle_categories: upravuje správce" on public.puzzle_categories;
create policy "puzzle_categories: upravuje správce" on public.puzzle_categories
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

insert into public.puzzle_categories (id, label, icon_name, sort) values
  ('cesko', 'Česko: města a místa', 'location_city', 10),
  ('svet', 'Svět: státy a města', 'public', 20),
  ('priroda', 'Zvířata a příroda', 'pets', 30),
  ('jidlo', 'Jídlo a pití', 'restaurant', 40),
  ('domov', 'Domov a věci', 'chair_alt', 50),
  ('doprava', 'Doprava a technika', 'directions_car', 60),
  ('lide', 'Lidé a povolání', 'groups', 70),
  ('mista', 'Místa a stavby', 'home_work', 80),
  ('kultura', 'Kultura a sport', 'theater_comedy', 90),
  ('pohadky', 'Pohádky a fantasy', 'auto_awesome', 100),
  ('veda', 'Věda a tělo', 'science', 110),
  ('cinnosti', 'Činnosti (slovesa)', 'directions_run', 120),
  ('pojmy', 'Pojmy a čas', 'lightbulb_outline', 130),
  ('other', 'Ostatní', 'more_horiz', 1000)
on conflict (id) do nothing;

-- Sada rébusu ('other' = Ostatní).
alter table public.puzzles
  add column if not exists category text not null default 'other'
  references public.puzzle_categories (id) on update cascade;

-- Zařazení stávajících rébusů podle řešení.
update public.puzzles set category = case
  when lower(btrim(solution)) in ('beroun', 'brod', 'horymír', 'jihlava', 'karlín', 'kladruby', 'kyjov', 'křivoklátsko', 'letohrad', 'morava', 'pardubice', 'podkrkonoší', 'poděbrady', 'prachatice', 'praděd', 'pálava', 'salaš', 'strakonice', 'vinohrad', 'vinohrady', 'čáslav') then 'cesko'
  when lower(btrim(solution)) in ('angola', 'barcelona', 'bombaj', 'evropa', 'jakarta', 'jamajka', 'kanada', 'kavkaz', 'kostarika', 'maledivy', 'maroko', 'mezinárodní', 'pákistán', 'turecko') then 'svet'
  when lower(btrim(solution)) in ('bobule', 'bodlinka', 'chobotnice', 'hřebík', 'kamenolom', 'kapr', 'kavka', 'kopec', 'kráva', 'květen', 'květináč', 'kůň', 'lenochod', 'lýkožrout', 'mokřad', 'mokřady', 'netopýr', 'okůrka', 'ostrov', 'panda', 'pavouk', 'pobřeží', 'rokle', 'rybolov', 'sedmikráska', 'světluška', 'tulipán', 'varan', 'velryba', 'venkov', 'vlašťovka', 'vlkodav', 'včelička', 'vřesoviště', 'zubr') then 'priroda'
  when lower(btrim(solution)) in ('ananas', 'bonbon', 'borůvka', 'brambora', 'brusinky', 'droždí', 'jahoda', 'jeřabina', 'karamel', 'káva', 'lednice', 'lékořice', 'malina', 'mrkve', 'omeleta', 'omáčka', 'pastvina', 'pecka', 'pivovar', 'prazdroj', 'rybíz', 'sekt', 'sendvič', 'sklovina', 'slonovina', 'svíčková', 'voda', 'vývar', 'žvýkačka') then 'jidlo'
  when lower(btrim(solution)) in ('balón', 'drátěnka', 'hrabě', 'hábit', 'kabelka', 'kapesník', 'karimatka', 'kartáček', 'katana', 'kladivo', 'kostky', 'krabice', 'kravata', 'kulich', 'lavice', 'medaile', 'mikina', 'nálevka', 'návlek', 'nůžky', 'paklíč', 'pantofle', 'pastelka', 'pistole', 'plášť', 'podlaha', 'podnos', 'postel', 'povlak', 'prsten', 'pánvička', 'sněhulák', 'studna', 'stůl', 'světlo', 'tabule', 'televize', 'tepláky', 'troud', 'trám', 'ubrousek', 'vanička', 'vstupenka', 'vysavač', 'zvonek', 'čelovka', 'čepice', 'železo', 'židle') then 'domov'
  when lower(btrim(solution)) in ('automobil', 'bagr', 'bankomat', 'brána', 'dron', 'fotovoltaika', 'karanténa', 'kartón', 'kokpit', 'manometr', 'modem', 'motokára', 'motor', 'motorka', 'parkování', 'parník', 'pneumatika', 'přímotop', 'semafor', 'traktor', 'vlak', 'voliéra', 'vrtule', 'zastávka', 'závora') then 'doprava'
  when lower(btrim(solution)) in ('artur', 'hvězdář', 'kat', 'kozák', 'královna', 'králíček', 'kulturista', 'lakomec', 'lunochod', 'pirát', 'prokuratura', 'reportér', 'senioři', 'starosta', 'virtuóz', 'zákonodárce', 'žena') then 'lide'
  when lower(btrim(solution)) in ('centrum', 'chata', 'chaty', 'dvoreček', 'kostel', 'kráter', 'metropole', 'náves', 'propast', 'sauna', 'vesmír', 'vyhlídka', 'zahrada', 'záhon', 'zákoutí', 'škola') then 'mista'
  when lower(btrim(solution)) in ('autobiografie', 'autogramiáda', 'diplom', 'hoboj', 'kaleidoskop', 'lampión', 'lunapark', 'metafora', 'ohňostroj', 'opona', 'paragraf', 'podium', 'trumpeta', 'volejbal') then 'kultura'
  when lower(btrim(solution)) in ('drak', 'elf', 'golem', 'ježibaba', 'kostlivec', 'netvor', 'pastorka', 'popelka', 'rébus', 'umpalumpa') then 'pohadky'
  when lower(btrim(solution)) in ('armatura', 'dekagram', 'duch', 'kost', 'kout', 'oko', 'onkologie', 'statika', 'ucho', 'výron') then 'veda'
  when lower(btrim(solution)) in ('dělat', 'lámat', 'navázat', 'podpálit', 'sušit', 'vlastnit', 'vypnutí', 'válet') then 'cinnosti'
  when lower(btrim(solution)) in ('exkurze', 'hodiny', 'hromada', 'jinotaj', 'kalamita', 'karneval', 'korekce', 'kouzla', 'leden', 'liposukce', 'logistika', 'myšlenka', 'nadvláda', 'naděje', 'nocleh', 'ples', 'podpora', 'pohyby', 'pokrok', 'píseň', 'předkolo', 'rakve', 'recenze', 'reklama', 'rekord', 'sleva', 'spára', 'srpen', 'status', 'tisíc', 'trhlina', 'tropimasohryz', 'vedení', 'vzduch', 'válka', 'víkend', 'výjimka', 'výtvor', 'záplaty', 'úplata', 'červen') then 'pojmy'
  else category
end
where category = 'other';
