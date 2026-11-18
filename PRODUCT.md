# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users
Casual Czech-speaking players (adults and teens) who play a few picture rébuses in short breaks (commute, evening) on their phone, mostly solo. A smaller group creates and uploads their own puzzles. Interface language is Czech.

## Product Purpose
Rébusárna is a mobile game (Flutter: Android, iOS, plus a web build) of picture rébuses. The player infers a hidden word from a single image, types a guess, and the app compares it with the solution ignoring case, diacritics and extra spaces. Success: players solve puzzles in quick sessions, keep a streak, come back, and some contribute their own.

## Positioning
Purpose-made Czech picture rébuses (wordplay built on Czech words and diacritics, with ?/± clue labels) authored by the owner, combined with a moderated community layer where difficulty is calculated from real player results rather than the author's guess. A generic puzzle app cannot copy the Czech-specific content and the player-calibrated difficulty together.

## Operating Context
- Play: a feed of cards (swipe or "Další"); puzzles cannot be searched or browsed, deliberately, so the game isn't made trivial. Hints are staged (1st: letter count, 2nd: first letter), "Ukázat řešení" breaks the streak, heart = favourite.
- Card label: `?` always; `±` when the solution has no accented acute character (á é í ó ú ý); word type; colour = difficulty (1 turquoise, 2 yellow, 3 red).
- Create: pick an image from the gallery, solution, word type, difficulty, meaning, live card preview, publish.
- "Moje": created, solved, favourite puzzles, reset progress, 18+ toggle, admin moderation queue.
- Play works without login with local progress; login (Google via Supabase) is needed to upload, and merges progress across devices.

## Capabilities and Constraints
- Stack exists: Flutter, Riverpod, go_router, Supabase (auth, tables, storage with RLS).
- Difficulty is computed from signed-in players' first attempts (wrong guesses, hints, shown solution), smoothed with the author's rating.
- 18+ self-declared flag, hidden by default; players can report puzzles; admins moderate.
- Layout must work from 360 px width; light and dark themes exist.
- Terminology (Czech): rébus, tip, nápověda, řešení, série, oblíbené, Moje, Hrát, Tvořit.
- Not yet built: ratings (fields prepared), daily puzzle, server-side guess verification.

## Brand Commitments
Working name "Rébusárna" (constant `kAppName`, may change). The owner authors the 114 built-in puzzle images; solutions are not to be derived from the pictures without the owner's verification. Platform decision: one custom design on all devices, not per-OS native conventions.

## Evidence on Hand
- 114 seed puzzles in `assets/images/` (WebP, 800 px) described by `assets/seed_puzzles.json`; word type and difficulty were auto-filled and "how to reach the solution" is blank.
- Supabase migrations in `supabase/migrations/`.
- No testimonials, ratings, store reviews or user numbers exist; do not invent them.

## Product Principles
1. The puzzle image is the hero; chrome stays out of the way of a 30-second session.
2. Don't make the game easier: no search or browsing of solutions, hints are staged and cost something.
3. Czech first: copy, diacritic-aware matching and tone are written for Czech speakers, not translated.
4. Play before sign-in: login is only asked for when it unlocks something (upload, sync).
5. Difficulty and quality are earned from players' behaviour and moderation, not asserted.

## Accessibility & Inclusion
Usable from 360 px width in light and dark themes. Colour-coded difficulty must not rely on colour alone. No further product-specific standard established.
