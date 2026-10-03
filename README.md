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

## Co je hotové a co zbývá

Hotovo: viz výše (hraní, tvorba, knihovna, Moje, světlé i tmavé téma, použitelné od šířky 360 px, unit a widget testy).

Zbývá (mimo rozsah MVP): backend (Supabase), přihlášení, sdílení mezi uživateli, moderace, hodnocení (pole `ratingSum`/`ratingCount` v modelu jsou připravená), denní rébus.

## Seed rébusy (114)

Druh slova a obtížnost jsem u vestavěných rébusů doplnil automaticky (obtížnost podle délky řešení, vše kromě „Válet" a „Podpálit" jako podstatné jméno). Uprav je v `assets/seed_puzzles.json`. Sloupec „Jak se k řešení dospěje" je prázdný k doplnění: autorem obrázků jsi ty a řešení nechci odvozovat od obrázku bez ověření.

| # | Obrázek | Řešení | Druh slova | Obtížnost | Jak se k řešení dospěje |
|---|---|---|---|---|---|
| 1 | `Ananas.png` | Ananas | podstatné jméno | 1 |  |
| 2 | `Artur.png` | Artur | podstatné jméno | 1 |  |
| 3 | `Balón_v1.1.png` | Balón | podstatné jméno | 1 |  |
| 4 | `Balón_v1.png` | Balón | podstatné jméno | 1 |  |
| 5 | `Beroun v2.png` | Beroun | podstatné jméno | 1 |  |
| 6 | `Beroun.png` | Beroun | podstatné jméno | 1 |  |
| 7 | `Borůvka.png` | Borůvka | podstatné jméno | 2 |  |
| 8 | `Brambora.png` | Brambora | podstatné jméno | 2 |  |
| 9 | `Brod.png` | Brod | podstatné jméno | 1 |  |
| 10 | `Brána.png` | Brána | podstatné jméno | 1 |  |
| 11 | `Chata.png` | Chata | podstatné jméno | 1 |  |
| 12 | `Chaty.png` | Chaty | podstatné jméno | 1 |  |
| 13 | `Diplom.png` | Diplom | podstatné jméno | 1 |  |
| 14 | `Dron_v1.png` | Dron | podstatné jméno | 1 |  |
| 15 | `Dron_v2.png` | Dron | podstatné jméno | 1 |  |
| 16 | `Evropa.png` | Evropa | podstatné jméno | 1 |  |
| 17 | `Evropa_v2.png` | Evropa | podstatné jméno | 1 |  |
| 18 | `Exkurze_v1.png` | Exkurze | podstatné jméno | 2 |  |
| 19 | `Exkurze_v2.png` | Exkurze | podstatné jméno | 2 |  |
| 20 | `Hodiny.png` | Hodiny | podstatné jméno | 1 |  |
| 21 | `Horymír.png` | Horymír | podstatné jméno | 2 |  |
| 22 | `Hromada.png` | Hromada | podstatné jméno | 2 |  |
| 23 | `Hřebík.png` | Hřebík | podstatné jméno | 1 |  |
| 24 | `Hřebík_v1.1.jpeg` | Hřebík | podstatné jméno | 1 |  |
| 25 | `Jahoda.png` | Jahoda | podstatné jméno | 1 |  |
| 26 | `Jakarta_v1.png` | Jakarta | podstatné jméno | 2 |  |
| 27 | `Jakarta_v2.png` | Jakarta | podstatné jméno | 2 |  |
| 28 | `Kabelka.png` | Kabelka | podstatné jméno | 2 |  |
| 29 | `Kalamita.png` | Kalamita | podstatné jméno | 2 |  |
| 30 | `Kapesník.png` | Kapesník | podstatné jméno | 2 |  |
| 31 | `Kopec_v1.png` | Kopec | podstatné jméno | 1 |  |
| 32 | `Kopec_v2.png` | Kopec | podstatné jméno | 1 |  |
| 33 | `Kostel.png` | Kostel | podstatné jméno | 1 |  |
| 34 | `Kráva.png` | Kráva | podstatné jméno | 1 |  |
| 35 | `Květináč.png` | Květináč | podstatné jméno | 2 |  |
| 36 | `Káva.png` | Káva | podstatné jméno | 1 |  |
| 37 | `Křivoklátsko.png` | Křivoklátsko | podstatné jméno | 3 |  |
| 38 | `Lenochod.png` | Lenochod | podstatné jméno | 2 |  |
| 39 | `Letohrad_v1.png` | Letohrad | podstatné jméno | 2 |  |
| 40 | `Letohrad_v2.png` | Letohrad | podstatné jméno | 2 |  |
| 41 | `Maledivy_v1.png` | Maledivy | podstatné jméno | 2 |  |
| 42 | `Maledivy_v2.png` | Maledivy | podstatné jméno | 2 |  |
| 43 | `Maroko_v1.png` | Maroko | podstatné jméno | 1 |  |
| 44 | `Maroko_v2.png` | Maroko | podstatné jméno | 1 |  |
| 45 | `Medaile.png` | Medaile | podstatné jméno | 2 |  |
| 46 | `Mokřady.png` | Mokřady | podstatné jméno | 2 |  |
| 47 | `Motorka.png` | Motorka | podstatné jméno | 2 |  |
| 48 | `Myšlenka.png` | Myšlenka | podstatné jméno | 2 |  |
| 49 | `Naděje.png` | Naděje | podstatné jméno | 1 |  |
| 50 | `Netopýr.png` | Netopýr | podstatné jméno | 2 |  |
| 51 | `Netvor.png` | Netvor | podstatné jméno | 1 |  |
| 52 | `Nálevka.png` | Nálevka | podstatné jméno | 2 |  |
| 53 | `Náves.png` | Náves | podstatné jméno | 1 |  |
| 54 | `Návlek.png` | Návlek | podstatné jméno | 1 |  |
| 55 | `Okůrka.png` | Okůrka | podstatné jméno | 1 |  |
| 56 | `Omeleta.png` | Omeleta | podstatné jméno | 2 |  |
| 57 | `Omáčka.png` | Omáčka | podstatné jméno | 1 |  |
| 58 | `Ostrov.png` | Ostrov | podstatné jméno | 1 |  |
| 59 | `Ostrov_v2.png` | Ostrov | podstatné jméno | 1 |  |
| 60 | `Paragraf.png` | Paragraf | podstatné jméno | 2 |  |
| 61 | `Paragraf_v1.1.png` | Paragraf | podstatné jméno | 2 |  |
| 62 | `Parkování.png` | Parkování | podstatné jméno | 2 |  |
| 63 | `Pastvina.png` | Pastvina | podstatné jméno | 2 |  |
| 64 | `Plášť.png` | Plášť | podstatné jméno | 1 |  |
| 65 | `Pneumatika.PNG` | Pneumatika | podstatné jméno | 3 |  |
| 66 | `Pobřeží.png` | Pobřeží | podstatné jméno | 2 |  |
| 67 | `Podlaha.png` | Podlaha | podstatné jméno | 2 |  |
| 68 | `Podnos.png` | Podnos | podstatné jméno | 1 |  |
| 69 | `Podpora.png` | Podpora | podstatné jméno | 2 |  |
| 70 | `Podpálit.png` | Podpálit | sloveso | 2 |  |
| 71 | `Pohyby.png` | Pohyby | podstatné jméno | 1 |  |
| 72 | `Prachatice.png` | Prachatice | podstatné jméno | 3 |  |
| 73 | `Prsten.png` | Prsten | podstatné jméno | 1 |  |
| 74 | `Páreček.png` | Páreček | podstatné jméno | 2 |  |
| 75 | `Předkolo.png` | Předkolo | podstatné jméno | 2 |  |
| 76 | `Přímotop.png` | Přímotop | podstatné jméno | 2 |  |
| 77 | `Semafor.png` | Semafor | podstatné jméno | 2 |  |
| 78 | `Sleva.png` | Sleva | podstatné jméno | 1 |  |
| 79 | `Sněhulák.png` | Sněhulák | podstatné jméno | 2 |  |
| 80 | `Starosta.png` | Starosta | podstatné jméno | 2 |  |
| 81 | `Statika.png` | Statika | podstatné jméno | 2 |  |
| 82 | `Strakonice.png` | Strakonice | podstatné jméno | 3 |  |
| 83 | `Svíčková.png` | Svíčková | podstatné jméno | 2 |  |
| 84 | `Světlo.png` | Světlo | podstatné jméno | 1 |  |
| 85 | `Tabule.png` | Tabule | podstatné jméno | 1 |  |
| 86 | `Televize.png` | Televize | podstatné jméno | 2 |  |
| 87 | `Traktor.png` | Traktor | podstatné jméno | 2 |  |
| 88 | `Trhlina_v1.png` | Trhlina | podstatné jméno | 2 |  |
| 89 | `Trhlina_v2.png` | Trhlina | podstatné jméno | 2 |  |
| 90 | `Tropimasohryz.png` | Tropimasohryz | podstatné jméno | 3 |  |
| 91 | `Vanička.png` | Vanička | podstatné jméno | 2 |  |
| 92 | `Venkov.png` | Venkov | podstatné jméno | 1 |  |
| 93 | `Vinohrady.png` | Vinohrady | podstatné jméno | 2 |  |
| 94 | `Virtuóz.png` | Virtuóz | podstatné jméno | 2 |  |
| 95 | `Voliéra.png` | Voliéra | podstatné jméno | 2 |  |
| 96 | `Vrtule.png` | Vrtule | podstatné jméno | 1 |  |
| 97 | `Válet.png` | Válet | sloveso | 1 |  |
| 98 | `Válet_v2.png` | Válet | sloveso | 1 |  |
| 99 | `Válka.png` | Válka | podstatné jméno | 1 |  |
| 100 | `Vývar.png` | Vývar | podstatné jméno | 1 |  |
| 101 | `Včelička_v1.png` | Včelička | podstatné jméno | 2 |  |
| 102 | `Včelička_v2.png` | Včelička | podstatné jméno | 2 |  |
| 103 | `Zahrada.png` | Zahrada | podstatné jméno | 2 |  |
| 104 | `Zahrada_v2.png` | Zahrada | podstatné jméno | 2 |  |
| 105 | `Zastávka.png` | Zastávka | podstatné jméno | 2 |  |
| 106 | `Zastávka_v1.1.png` | Zastávka | podstatné jméno | 2 |  |
| 107 | `Záplaty.png` | Záplaty | podstatné jméno | 2 |  |
| 108 | `autogramiáda.png` | autogramiáda | podstatné jméno | 3 |  |
| 109 | `fotovoltaika.png` | fotovoltaika | podstatné jméno | 3 |  |
| 110 | `kalamita_v2.png` | kalamita | podstatné jméno | 2 |  |
| 111 | `Úplata.png` | Úplata | podstatné jméno | 1 |  |
| 112 | `Čelovka.png` | Čelovka | podstatné jméno | 2 |  |
| 113 | `Čáslav.png` | Čáslav | podstatné jméno | 1 |  |
| 114 | `Židle.png` | Židle | podstatné jméno | 1 |  |

## Doporučení

Obrázky mají dohromady asi 250 MB (až 3,5 MB na soubor). Před vydáním je zmenši, např. na šířku 1024 px.
