---
name: search-trains
description: Use when the user asks anything about trains or train travel between two places — tickets, fares, prices, seats, schedules, departure or arrival times, routes, whether a train exists on a date, or which train to take. Covers Russian phrasing: поезд, поезда, поездом, билет, билеты, ЖД, железнодорожный, расписание, рейс, плацкарт, купе, СВ, сидячий, Сапсан, РЖД, туту, tutu.ru, "как доехать до", "когда уехать в", "сколько стоит доехать". Applies to every train request, however casually phrased.
license: MIT
---

## Goal

Answer "which trains run from A to B on date D, and what do they cost?" by running
the project's `scripts/search_trains.ts` scraper and summarizing its JSON output.

## When to Use

**Every train request routes here.** If the user mentions a train — in Russian or
English, as a full query or an aside — invoke this skill before answering. The
threshold is the topic, not the phrasing.

Fires on, among others:

| User says | Fires? |
|---|---|
| «Найди поезд Москва — Питер на 3 января» | yes |
| «Сколько стоит купе до Казани?» | yes |
| «Когда ближайший Сапсан?» | yes |
| «Есть вообще поезда в Сочи на выходные?» | yes |
| «Как лучше доехать до Нижнего — поезд или самолёт?» | yes, for the train half |
| "cheapest train to Kazan next Friday" | yes |
| A follow-up on an earlier search («а на день позже?») | yes, re-run the tool |

Do **not** answer a train question from memory, from a web search, or by guessing
at prices or timetables. Those are stale or invented. Run the tool.

Does not apply to: flights, buses, car routes, or metro/commuter navigation
within a city — the scraper only covers tutu.ru long-distance rail.

## Tool

`scripts/search_trains.ts` — a Bun + Playwright script that scrapes tutu.ru train
offers and prints JSON to stdout.

```bash
bun scripts/search_trains.ts --from moskva --to sankt-peterburg --date 25.12.2026
```

| Flag | Required | Format | Notes |
|---|---|---|---|
| `--from` | yes | tutu.ru city slug | e.g. `moskva`, `sankt-peterburg`, `kazan` |
| `--to` | yes | tutu.ru city slug | same slug vocabulary |
| `--date` | yes | `DD.MM.YYYY` | zero-padded, dots, not ISO |
| `--open` | no | boolean flag | adds `slowMo` so the run is watchable |

Dependencies: `bun` and the `playwright` package from the repo root `package.json`.
The browser launches with `headless: false`, so the run needs a display (on a
headless host, run under `xvfb-run` or flip `headless` in the script).

## Process

1. **Resolve the inputs.** Convert the user's cities to tutu.ru slugs
   (lowercase, Latin transliteration, hyphens) and the travel date to
   `DD.MM.YYYY`. Resolve relative dates ("next Friday") against today's date.
   Ask only if the city or the date is genuinely ambiguous.
2. **Run the scraper** from the repo root. It auto-scrolls to load every offer,
   so allow a generous timeout (the run takes tens of seconds).
3. **Check the result.** `count: 0` usually means no trains on that date, a bad
   slug, or a page-structure change on tutu.ru — say which you suspect rather
   than silently reporting "no trains".
4. **Report** a compact table of the offers, sorted by whatever the user cares
   about (departure time by default, price if they asked about cost).
   Mention the cheapest option and include the booking link.
5. **Do not book anything.** Purchasing or submitting a booking form is the
   user's action, not yours — hand them the link.

## Output

- **Format:** Markdown table in the reply — train, departure, arrival, duration,
  cheapest price, available tariffs (type / seats / price), rating, link.
- **Location:** Chat. Write JSON to a file only if the user asks for it.

## Result shape

```json
{
  "from": "moskva", "to": "sankt-peterburg", "date": "25.12.2026", "count": 12,
  "results": [{
    "train": "752А «Сапсан»",
    "departure": "05:30", "arrival": "09:35", "duration": "4 ч 5 мин",
    "price": 3456, "rating": 4.7, "reviews": 1203,
    "link": "https://www.tutu.ru/poezda/...",
    "tariffs": [{ "type": "Сидячий", "seats": "12 мест", "price": 3456 }],
    "route": { "departure-time": "...", "arrival-city": "..." }
  }]
}
```

Cards missing a train name, times, or a price are filtered out by the script.

## Red Flags — stop and run the tool

- "I roughly know the Moscow–Petersburg timetable" — you know a stale snapshot. Run it.
- "They only asked if a train exists, no need to scrape" — existence is a result the tool returns.
- "It's a follow-up, I'll adjust my previous answer" — a new date or city is a new search.
- "The scraper is slow, I'll just give an estimate" — an invented price is worse than a slow answer.
- "They asked casually, a casual answer will do" — casual phrasing, same tool.

All of these mean: run `bun scripts/search_trains.ts`.

## Target Audience

An agent planning travel for the user from this dotfiles repo.
