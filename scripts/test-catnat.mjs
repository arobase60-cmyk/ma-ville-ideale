import fs from "fs";

const csv = fs.readFileSync("data/catnat.csv", "utf8");

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

const tautavel = events.filter(
  (event) =>
    event.code === "66205" &&
    event.risk === "Inondations"
);

const recent = tautavel.filter((event) => {
  const date = new Date(event.start);
  return date >= tenYearsAgo && date <= today;
});

console.log("");
console.log("===== TEST CAT-NAT TAUTAVEL =====");
console.log("");

console.log(
  "Total depuis 1982 :",
  tautavel.length
);

console.log(
  "Sur les 10 dernières années :",
  recent.length
);

const lastEvent = tautavel
  .slice()
  .sort(
    (a, b) =>
      new Date(b.start) - new Date(a.start)
  )[0];

console.log(
  "Dernier événement :",
  lastEvent
    ? lastEvent.start
    : "Aucun"
);
console.log("");