import fs from "fs";
import path from "path";

const projectRoot = process.cwd();

const csvFile = path.join(projectRoot, "data", "catnat.csv");
const departementsFolder = path.join(
  projectRoot,
  "public",
  "data",
  "departements"
);

console.log("");
console.log("=====================================");
console.log("INJECTION CAT-NAT - DEPARTEMENTS");
console.log("=====================================");
console.log("");

const csv = fs.readFileSync(csvFile, "utf8").replace(/^\uFEFF/, "");

const lines = csv
  .split(/\r?\n/)
  .filter(Boolean);

console.log("Lignes CSV :", lines.length);

// ==================================================
// INDEX CAT-NAT
// ==================================================

const eventsByCode = new Map();

for (const line of lines) {

  const values = line.split(";");

  // Une vraie ligne de commune commence par :
  // numéro interne ; code INSEE ; nom commune
  if (
    values.length < 16 ||
    !/^\d+$/.test(values[0]?.trim()) ||
    !/^\d{5}$/.test(values[1]?.trim())
  ) {
    continue;
  }

  const code = values[1].trim();
  const risk = values[12]?.trim();

  // Uniquement les inondations
  if (risk !== "Inondations") {
    continue;
  }

  const start = values[13]?.trim() || "";

  if (!start) {
    continue;
  }

  if (!eventsByCode.has(code)) {
    eventsByCode.set(code, []);
  }

  eventsByCode.get(code).push({
    start
  });
}

console.log(
  "Communes avec événements Inondations :",
  eventsByCode.size
);

// ==================================================
// PERIODE
// ==================================================

const today = new Date("2026-08-20T00:00:00");

const tenYearsAgo = new Date(today);
tenYearsAgo.setFullYear(
  tenYearsAgo.getFullYear() - 10
);

// ==================================================
// TRAITEMENT DES DEPARTEMENTS
// ==================================================

let totalFiles = 0;
let totalCities = 0;
let totalWithCatnat = 0;

const files = fs
  .readdirSync(departementsFolder)
  .filter(file => file.endsWith(".json"));

for (const filename of files) {

  const filePath = path.join(
    departementsFolder,
    filename
  );

  try {

    const cities = JSON.parse(
      fs.readFileSync(filePath, "utf8")
    );

    let departmentWithCatnat = 0;

    for (const city of cities) {

      const code = String(city.code)
        .trim()
        .padStart(5, "0");

      const cityEvents =
        eventsByCode.get(code) || [];

      const recentEvents = cityEvents.filter(
        event => {

          const date = new Date(event.start);

          return (
            date >= tenYearsAgo &&
            date <= today
          );
        }
      );

      const sortedEvents =
        [...cityEvents].sort(
          (a, b) =>
            new Date(b.start) -
            new Date(a.start)
        );

      const lastEvent =
        sortedEvents.length > 0
          ? sortedEvents[0].start.substring(0, 10)
          : null;

      // On conserve l'objet risks existant
      // et on ne touche à aucune autre donnée.

      city.risks = {
        ...(city.risks || {}),
        floodCatNat: cityEvents.length,
        floodCatNat10Years: recentEvents.length,
        lastFloodCatNat: lastEvent
      };

      if (cityEvents.length > 0) {
        departmentWithCatnat++;
        totalWithCatnat++;
      }
    }

    // Sauvegarde
    const backupPath =
      `${filePath}.bak`;

    if (!fs.existsSync(backupPath)) {
      fs.copyFileSync(
        filePath,
        backupPath
      );
    }

    fs.writeFileSync(
      filePath,
      JSON.stringify(cities, null, 2),
      "utf8"
    );

    console.log(
      `${filename.replace(".json", "")} : ` +
      `${cities.length} communes - ` +
      `Cat-Nat : ${departmentWithCatnat}`
    );

    totalFiles++;
    totalCities += cities.length;

  } catch (error) {

    console.log(
      `${filename} : ERREUR :`,
      error.message
    );
  }
}

console.log("");
console.log("=====================================");
console.log("CAT-NAT TERMINE");
console.log("=====================================");
console.log("Fichiers traites :", totalFiles);
console.log("Communes traitees :", totalCities);
console.log(
  "Communes avec Cat-Nat :",
  totalWithCatnat
);
console.log("=====================================");