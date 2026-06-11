#!/usr/bin/env bun

import { chromium } from "playwright";

type Args = {
  from: string;
  to: string;
  date: string;
  open: boolean;
};

function parseArgs(): Args {
  const args = process.argv.slice(2);
  const map: Record<string, any> = {};

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];

    if (!arg.startsWith("--")) continue;

    const key = arg.slice(2);

    if (key === "open") {
      map.open = true;
      continue;
    }

    map[key] = args[i + 1];
    i++;
  }

  if (!map.from || !map.to || !map.date) {
    console.error(
      "Usage: --from X --to Y --date DD.MM.YYYY [--open]"
    );
    process.exit(1);
  }

  return {
    from: map.from,
    to: map.to,
    date: map.date,
    open: Boolean(map.open ?? false)
  };
}

async function searchTrains({ from, to, date, open }: Args) {
  const browser = await chromium.launch({
    headless: false,
    // headless: !open,
    slowMo: open ? 30 : 0
  });

  const page = await browser.newPage();

  await page.setExtraHTTPHeaders({
    "User-Agent":
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120 Safari/537.36"
  });

  const url = `https://www.tutu.ru/poezda/${from}/${to}/?date=${date}&travelers=1`;

  await page.goto(url, { waitUntil: "domcontentloaded" });

  // wait initial render
  await page.waitForTimeout(3000);

  // =========================
  // AUTO SCROLL TO LOAD ALL
  // =========================
  let previousHeight = 0;
  let stableRounds = 0;

  while (stableRounds < 3) {
    const currentHeight = await page.evaluate(() => document.body.scrollHeight);

    await page.evaluate(() => {
      window.scrollTo(0, document.body.scrollHeight);
    });

    await page.waitForTimeout(2000);

    if (currentHeight === previousHeight) {
      stableRounds++;
    } else {
      stableRounds = 0;
      previousHeight = currentHeight;
    }
  }

  // =========================
  // SCRAPE
  // =========================
  const results = await page.evaluate(() => {
    const cards = Array.from(
      document.querySelectorAll('[data-ti="offer-card"]')
    );

    const clean = (s: string | null | undefined) =>
      s?.replace(/\s+/g, " ").trim() ?? null;

    const getText = (el: Element | null) => clean(el?.textContent);

    const parseMoney = (text: string | null) => {
      if (!text) return null;
      const match = text.replace(/\u202f/g, " ").match(/(\d[\d\s]*)\s?₽/);
      return match ? Number(match[1].replace(/\s/g, "")) : null;
    };

    const extractLabelValuePairs = (root: Element) => {
      const items: Record<string, string> = {};

      const nodes = root.querySelectorAll("[data-ti]");

      nodes.forEach(node => {
        const key = node.getAttribute("data-ti");
        const value = clean(node.textContent);

        if (!key || !value) return;

        // keep only meaningful primitives
        if (
          key.includes("time") ||
            key.includes("place") ||
            key.includes("city") ||
            key.includes("date") ||
            key.includes("duration")
        ) {
          items[key] = value;
        }
      });

      return items;
    };

    const extractTariffs = (card: Element) => {
      const tariffs: any[] = [];

      const tariffButtons = card.querySelectorAll('[data-ti="offer-tariff"]');

      tariffButtons.forEach(btn => {
        const text = clean(btn.textContent);

        if (!text) return;

        const price = parseMoney(text);

        const label =
          btn.querySelector('[data-ti="label-value-label"]')?.textContent ??
          null;

        const seats =
          btn.querySelector('[data-ti="label-value-value"]')?.textContent ??
          null;

        if (!price) return;

        tariffs.push({
          type: clean(label),
          seats: clean(seats),
          price
        });
      });

      return tariffs;
    };

    return cards.map(card => {
      const trainBadge =
        card.querySelector('[data-ti="train-name-badge"]')?.textContent;

      const departure = card.querySelector('[data-ti="departure-time"]');
      const arrival = card.querySelector('[data-ti="arrival-time"]');
      const duration = card.querySelector('[data-ti="duration-time"]');

      const priceNodes = Array.from(
        card.querySelectorAll("[data-ti]")
      )
        .map(n => n.textContent || "")
        .find(t => t.includes("₽"));

      const link =
        card.querySelector('a[href*="/poezda/"]')?.getAttribute("href") ??
        null;

      const reviews =
        card
          .querySelector('[data-ti="rating"]')
        ?.textContent?.match(/\d+/)?.[0] ?? null;

      const rating =
        card
          .querySelector('[data-ti="badge"]')
        ?.textContent?.match(/(\d+[,.]\d+)/)?.[1] ?? null;

      const routeInfo = extractLabelValuePairs(card);
      const tariffs = extractTariffs(card);

      const price = priceNodes ? priceNodes.match(/(\d[\d\s]+)/)?.[1] : null;

      return {
        train: clean(trainBadge),
        departure: clean(departure?.textContent),
        arrival: clean(arrival?.textContent),
        duration: clean(duration?.textContent),

        price: price ? Number(price.replace(/\s/g, "")) : null,

        rating: rating ? Number(rating.replace(",", ".")) : null,
        reviews: reviews ? Number(reviews) : null,

        link: link ? `https://www.tutu.ru${link}` : null,

        tariffs,
        route: routeInfo
      };
    })
    // IMPORTANT: filter invalid cards
      .filter(t =>
        t.train &&
        t.departure &&
        t.arrival &&
        t.price !== null
             );
  });

  await browser.close();

  return {
    from,
    to,
    date,
    count: results.length,
    results
  };
}

async function main() {
  const args = parseArgs();
  const data = await searchTrains(args);

  console.log(JSON.stringify(data, null, 2));
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
