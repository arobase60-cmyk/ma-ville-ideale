import fs from "fs";

const csv = fs.readFileSync("data/catnat.csv", "utf8");
 const municipalities = JSON.parse(
  fs.readFileSync("src/data/municipalities.json", "utf8").replace(/^\uFEFF/, "")
);

const lines = csv.split(/\r?\n/);

const headers = [
  "id",
  "code",
  "name",
  "epci",
  "epci_name",
  "dep",
  "dep_name",
  "zone",
  "a",
  "b",
  "c",
  "d",
  "risk",
  "start",
  "end",
  "published"
];

const events = lines
  .slice(1)
  .filter(Boolean)
  .map((line) => {
    const values = line.split(";");
    const row = {};

    headers.forEach((header, index) => {
      row[header] = values[index]?.trim() ?? "";
    });

    return row;
  });

const today = new Date("2026-08-20T00:00:00");

const tenYearsAgo = new Date(today);
tenYearsAgo.setFullYear(tenYearsAgo.getFullYear() - 10);

let updated = 0;

const result = municipalities.map((city) => {
  const code = String(city.code).padStart(5, "0");

  const cityEvents = events.filter(
    (event) =>
      event.code === code &&
      event.risk === "Inondations"
  );

  const recentEvents = cityEvents.filter((event) => {
    const date = new Date(event.start);
    return date >= tenYearsAgo && date <= today;
  });

  const sortedEvents = cityEvents
    .slice()
    .sort(
      (a, b) =>
        new Date(b.start) - new Date(a.start)
    );

  const lastEvent = sortedEvents[0];

  const risks = {
    ...(city.risks || {}),
    floodCatNat: cityEvents.length,
    floodCatNat10Years: recentEvents.length,
    lastFloodCatNat: lastEvent
      ? lastEvent.start.substring(0, 10)
      : null
  };

  if (cityEvents.length > 0) {
    updated++;
  }

  return {
    ...city,
    risks
  };
});

fs.writeFileSync(
  "src/data/municipalities-catnat-test.json",
  JSON.stringify(result, null, 2),
  "utf8"
);

console.log("");
console.log("===== MISE À JOUR CAT-NAT =====");
console.log("");
console.log("Communes traitées :", municipalities.length);
console.log("Communes avec Cat-Nat :", updated);
console.log("");
console.log(
  "Fichier créé : src/data/municipalities-catnat-test.json"
);