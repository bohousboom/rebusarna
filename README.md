# Rébusárna

Mobilní hra s obrázkovými rébusy (Flutter, Android + iOS, UI česky). Hráč z obrázku odvodí skryté slovo, zadá tip a aplikace ho porovná s řešením (bez ohledu na velikost písmen, diakritiku a mezery navíc).
Pracovní název je konstanta `kAppName` v [lib/core/constants.dart](lib/core/constants.dart).

## Jak spustit

```bash
flutter pub get
flutter run            # připojený telefon / emulátor
flutter run -d chrome  # webový náhled
flutter test           # testy
dart analyze           # analýza (viz poznámka níže)
```

Poznámka: `flutter analyze` může padat, když cesta k projektu obsahuje znaky jako „š" nebo „ť" (chyba analyzátoru). `dart analyze` dává stejný výsledek.

## Jak to funguje

- **Rébus = jeden hotový obrázek + řešení.** Vestavěné rébusy jsou v `assets/images/` (název souboru = řešení) a popisuje je `assets/seed_puzzles.json`.
- **Štítek karty:** `?` vždy; `±` právě když řešení neobsahuje žádný znak s čárkou (á é í ó ú ý, konstanta `kAcuteChars`); druh slova; barva = obtížnost (1 tyrkysová, 2 žlutá, 3 červená).
- **Hrát:** feed karet (swipe nebo „Další"), tip, nápověda (1. klik: počet písmen, 2. klik: první písmeno), „Ukázat řešení", série vyřešených v řadě (přeruší ji ukázání řešení), srdíčko = oblíbené.
- **Tvořit:** výběr obrázku z galerie, řešení, druh slova, obtížnost, význam, živý náhled karty, validace, „Zveřejnit" (zatím uloží jen do zařízení).
- **Knihovna:** galerie všech rébusů, hledání podle řešení bez diakritiky. Vyřešené ukazují řešení.
- **Moje:** vytvořené, vyřešené, oblíbené.

## Architektura

- `lib/domain/` čistá logika bez Flutter importů (`normalize`, `isCorrect`, `hasNoAcute`, nápovědy, hledání, validace) + modely.
- `lib/data/` repozitáře. `PuzzleRepository` je rozhraní, `LocalPuzzleRepository` ukládá JSON do `shared_preferences`. Pozdější `SupabasePuzzleRepository` stačí podstrčit přes `puzzleRepositoryProvider`, UI se nemění.
- `lib/presentation/` obrazovky a widgety (Riverpod, go_router).

## Supabase a přihlášení

- Backend: Supabase (přihlášení přes Google, tabulky `puzzles`, `solved`, `favorites`, `profiles`, úložiště `puzzle-images`). Schéma je v `supabase/migrations/`.
- URL a **publishable** klíč jsou v [lib/core/config.dart](lib/core/config.dart) jako výchozí hodnoty. Jsou určené pro veřejnou aplikaci, přístup hlídají pravidla (RLS) v databázi. `service_role` klíč nikdy nepatří do repa. Hodnoty jdou přepsat: `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...`.
- Bez přihlášení lze hrát, procházet knihovnu a mít postup lokálně. Nahrávat rébusy mohou jen přihlášení. Po přihlášení se postup (uhodnuté, oblíbené, série) sloučí s účtem a synchronizuje mezi zařízeními.
- Mobilní návrat z přihlášení: schéma `cz.rebusarna://login-callback` (Android manifest, iOS Info.plist). V Supabase (Authentication → URL Configuration) musí být v Redirect URLs: adresa webu `https://<doména>/**`, `http://localhost:*/**` a `cz.rebusarna://login-callback`.

## Co je hotové a co zbývá

Hotovo: viz výše (hraní, tvorba, knihovna, Moje, světlé i tmavé téma, použitelné od šířky 360 px, unit a widget testy).

Zbývá: moderace sdílených rébusů, mazání vlastních rébusů, hodnocení (pole `ratingSum`/`ratingCount` v modelu jsou připravená), denní rébus, ověřování tipu na serveru.

## Seed rébusy (114)

Druh slova a obtížnost jsem u vestavěných rébusů doplnil automaticky (obtížnost podle délky řešení, vše kromě „Válet" a „Podpálit" jako podstatné jméno). Uprav je v `assets/seed_puzzles.json`. Sloupec „Jak se k řešení dospěje" je prázdný k doplnění: autorem obrázků jsi ty a řešení nechci odvozovat od obrázku bez ověření.

| # | Obrázek | Řešení | Druh slova | Obtížnost | Jak se k řešení dospěje |
|---|---|---|---|---|---|
| 1 | `Ananas.webp` | Ananas | podstatné jméno | 1 |  |
| 2 | `Artur.webp` | Artur | podstatné jméno | 1 |  |
| 3 | `Balón_v1.1.webp` | Balón | podstatné jméno | 1 |  |
| 4 | `Balón_v1.webp` | Balón | podstatné jméno | 1 |  |
| 5 | `Beroun v2.webp` | Beroun | podstatné jméno | 1 |  |
| 6 | `Beroun.webp` | Beroun | podstatné jméno | 1 |  |
| 7 | `Borůvka.webp` | Borůvka | podstatné jméno | 2 |  |
| 8 | `Brambora.webp` | Brambora | podstatné jméno | 2 |  |
| 9 | `Brod.webp` | Brod | podstatné jméno | 1 |  |
| 10 | `Brána.webp` | Brána | podstatné jméno | 1 |  |
| 11 | `Chata.webp` | Chata | podstatné jméno | 1 |  |
| 12 | `Chaty.webp` | Chaty | podstatné jméno | 1 |  |
| 13 | `Diplom.webp` | Diplom | podstatné jméno | 1 |  |
| 14 | `Dron_v1.webp` | Dron | podstatné jméno | 1 |  |
| 15 | `Dron_v2.webp` | Dron | podstatné jméno | 1 |  |
| 16 | `Evropa.webp` | Evropa | podstatné jméno | 1 |  |
| 17 | `Evropa_v2.webp` | Evropa | podstatné jméno | 1 |  |
| 18 | `Exkurze_v1.webp` | Exkurze | podstatné jméno | 2 |  |
| 19 | `Exkurze_v2.webp` | Exkurze | podstatné jméno | 2 |  |
| 20 | `Hodiny.webp` | Hodiny | podstatné jméno | 1 |  |
| 21 | `Horymír.webp` | Horymír | podstatné jméno | 2 |  |
| 22 | `Hromada.webp` | Hromada | podstatné jméno | 2 |  |
| 23 | `Hřebík.webp` | Hřebík | podstatné jméno | 1 |  |
| 24 | `Hřebík_v1.1.jpeg` | Hřebík | podstatné jméno | 1 |  |
| 25 | `Jahoda.webp` | Jahoda | podstatné jméno | 1 |  |
| 26 | `Jakarta_v1.webp` | Jakarta | podstatné jméno | 2 |  |
| 27 | `Jakarta_v2.webp` | Jakarta | podstatné jméno | 2 |  |
| 28 | `Kabelka.webp` | Kabelka | podstatné jméno | 2 |  |
| 29 | `Kalamita.webp` | Kalamita | podstatné jméno | 2 |  |
| 30 | `Kapesník.webp` | Kapesník | podstatné jméno | 2 |  |
| 31 | `Kopec_v1.webp` | Kopec | podstatné jméno | 1 |  |
| 32 | `Kopec_v2.webp` | Kopec | podstatné jméno | 1 |  |
| 33 | `Kostel.webp` | Kostel | podstatné jméno | 1 |  |
| 34 | `Kráva.webp` | Kráva | podstatné jméno | 1 |  |
| 35 | `Květináč.webp` | Květináč | podstatné jméno | 2 |  |
| 36 | `Káva.webp` | Káva | podstatné jméno | 1 |  |
| 37 | `Křivoklátsko.webp` | Křivoklátsko | podstatné jméno | 3 |  |
| 38 | `Lenochod.webp` | Lenochod | podstatné jméno | 2 |  |
| 39 | `Letohrad_v1.webp` | Letohrad | podstatné jméno | 2 |  |
| 40 | `Letohrad_v2.webp` | Letohrad | podstatné jméno | 2 |  |
| 41 | `Maledivy_v1.webp` | Maledivy | podstatné jméno | 2 |  |
| 42 | `Maledivy_v2.webp` | Maledivy | podstatné jméno | 2 |  |
| 43 | `Maroko_v1.webp` | Maroko | podstatné jméno | 1 |  |
| 44 | `Maroko_v2.webp` | Maroko | podstatné jméno | 1 |  |
| 45 | `Medaile.webp` | Medaile | podstatné jméno | 2 |  |
| 46 | `Mokřady.webp` | Mokřady | podstatné jméno | 2 |  |
| 47 | `Motorka.webp` | Motorka | podstatné jméno | 2 |  |
| 48 | `Myšlenka.webp` | Myšlenka | podstatné jméno | 2 |  |
| 49 | `Naděje.webp` | Naděje | podstatné jméno | 1 |  |
| 50 | `Netopýr.webp` | Netopýr | podstatné jméno | 2 |  |
| 51 | `Netvor.webp` | Netvor | podstatné jméno | 1 |  |
| 52 | `Nálevka.webp` | Nálevka | podstatné jméno | 2 |  |
| 53 | `Náves.webp` | Náves | podstatné jméno | 1 |  |
| 54 | `Návlek.webp` | Návlek | podstatné jméno | 1 |  |
| 55 | `Okůrka.webp` | Okůrka | podstatné jméno | 1 |  |
| 56 | `Omeleta.webp` | Omeleta | podstatné jméno | 2 |  |
| 57 | `Omáčka.webp` | Omáčka | podstatné jméno | 1 |  |
| 58 | `Ostrov.webp` | Ostrov | podstatné jméno | 1 |  |
| 59 | `Ostrov_v2.webp` | Ostrov | podstatné jméno | 1 |  |
| 60 | `Paragraf.webp` | Paragraf | podstatné jméno | 2 |  |
| 61 | `Paragraf_v1.1.webp` | Paragraf | podstatné jméno | 2 |  |
| 62 | `Parkování.webp` | Parkování | podstatné jméno | 2 |  |
| 63 | `Pastvina.webp` | Pastvina | podstatné jméno | 2 |  |
| 64 | `Plášť.webp` | Plášť | podstatné jméno | 1 |  |
| 65 | `Pneumatika.webp` | Pneumatika | podstatné jméno | 3 |  |
| 66 | `Pobřeží.webp` | Pobřeží | podstatné jméno | 2 |  |
| 67 | `Podlaha.webp` | Podlaha | podstatné jméno | 2 |  |
| 68 | `Podnos.webp` | Podnos | podstatné jméno | 1 |  |
| 69 | `Podpora.webp` | Podpora | podstatné jméno | 2 |  |
| 70 | `Podpálit.webp` | Podpálit | sloveso | 2 |  |
| 71 | `Pohyby.webp` | Pohyby | podstatné jméno | 1 |  |
| 72 | `Prachatice.webp` | Prachatice | podstatné jméno | 3 |  |
| 73 | `Prsten.webp` | Prsten | podstatné jméno | 1 |  |
| 74 | `Páreček.webp` | Páreček | podstatné jméno | 2 |  |
| 75 | `Předkolo.webp` | Předkolo | podstatné jméno | 2 |  |
| 76 | `Přímotop.webp` | Přímotop | podstatné jméno | 2 |  |
| 77 | `Semafor.webp` | Semafor | podstatné jméno | 2 |  |
| 78 | `Sleva.webp` | Sleva | podstatné jméno | 1 |  |
| 79 | `Sněhulák.webp` | Sněhulák | podstatné jméno | 2 |  |
| 80 | `Starosta.webp` | Starosta | podstatné jméno | 2 |  |
| 81 | `Statika.webp` | Statika | podstatné jméno | 2 |  |
| 82 | `Strakonice.webp` | Strakonice | podstatné jméno | 3 |  |
| 83 | `Svíčková.webp` | Svíčková | podstatné jméno | 2 |  |
| 84 | `Světlo.webp` | Světlo | podstatné jméno | 1 |  |
| 85 | `Tabule.webp` | Tabule | podstatné jméno | 1 |  |
| 86 | `Televize.webp` | Televize | podstatné jméno | 2 |  |
| 87 | `Traktor.webp` | Traktor | podstatné jméno | 2 |  |
| 88 | `Trhlina_v1.webp` | Trhlina | podstatné jméno | 2 |  |
| 89 | `Trhlina_v2.webp` | Trhlina | podstatné jméno | 2 |  |
| 90 | `Tropimasohryz.webp` | Tropimasohryz | podstatné jméno | 3 |  |
| 91 | `Vanička.webp` | Vanička | podstatné jméno | 2 |  |
| 92 | `Venkov.webp` | Venkov | podstatné jméno | 1 |  |
| 93 | `Vinohrady.webp` | Vinohrady | podstatné jméno | 2 |  |
| 94 | `Virtuóz.webp` | Virtuóz | podstatné jméno | 2 |  |
| 95 | `Voliéra.webp` | Voliéra | podstatné jméno | 2 |  |
| 96 | `Vrtule.webp` | Vrtule | podstatné jméno | 1 |  |
| 97 | `Válet.webp` | Válet | sloveso | 1 |  |
| 98 | `Válet_v2.webp` | Válet | sloveso | 1 |  |
| 99 | `Válka.webp` | Válka | podstatné jméno | 1 |  |
| 100 | `Vývar.webp` | Vývar | podstatné jméno | 1 |  |
| 101 | `Včelička_v1.webp` | Včelička | podstatné jméno | 2 |  |
| 102 | `Včelička_v2.webp` | Včelička | podstatné jméno | 2 |  |
| 103 | `Zahrada.webp` | Zahrada | podstatné jméno | 2 |  |
| 104 | `Zahrada_v2.webp` | Zahrada | podstatné jméno | 2 |  |
| 105 | `Zastávka.webp` | Zastávka | podstatné jméno | 2 |  |
| 106 | `Zastávka_v1.1.webp` | Zastávka | podstatné jméno | 2 |  |
| 107 | `Záplaty.webp` | Záplaty | podstatné jméno | 2 |  |
| 108 | `autogramiáda.webp` | autogramiáda | podstatné jméno | 3 |  |
| 109 | `fotovoltaika.webp` | fotovoltaika | podstatné jméno | 3 |  |
| 110 | `kalamita_v2.webp` | kalamita | podstatné jméno | 2 |  |
| 111 | `Úplata.webp` | Úplata | podstatné jméno | 1 |  |
| 112 | `Čelovka.webp` | Čelovka | podstatné jméno | 2 |  |
| 113 | `Čáslav.webp` | Čáslav | podstatné jméno | 1 |  |
| 114 | `Židle.webp` | Židle | podstatné jméno | 1 |  |

## Doporučení

Obrázky jsou převedené na WebP (šířka 800 px, kvalita 82), dohromady asi 13 MB. Originály jsou zálohované mimo projekt ve složce „Lušťovky - originály obrázků" na ploše.
