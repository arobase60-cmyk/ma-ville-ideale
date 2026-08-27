import fs from "fs";
import readline from "readline";

const csvFile =
  "donnee-data.gouv-2025-geographie2026-produit-le2026-06-25.csv";

const jsonFile =
  "src/data/municipalities.json";

const municipalities = JSON.parse(
  fs.readFileSync(jsonFile, "utf8")
);

const data = new Map();

const stream = fs.createReadStream(csvFile, {
  encoding: "utf8"
});

const rl = readline.createInterface({
  input: stream,
  crlfDelay: Infinity
});

const wanted = [
  "Cambriolages de logement",
  "Vols dans les véhicules",
  "Vols de véhicule"
];

let firstLine = true;

for await (const line of rl) {

  if (firstLine) {
    firstLine = false;
    continue;
  }

  if (!line.trim()) continue;

  const values = line
    .split(";")
    .map(v => v.replace(/^"|"$/g, ""));

  const code = values[0];
  const year = values[1];
  const indicator = values[2];
  const rateText = values[5];
  const diffusion = values[6];

  if (year !== "2025") continue;
  if (!wanted.includes(indicator)) continue;
  if (!code.startsWith("66")) continue;
  if (diffusion !== "diff") continue;

  const rate = Number(
    rateText.replace(",", ".")
  );

  if (!Number.isFinite(rate)) continue;

  if (!data.has(code)) {
    data.set(code, {});
  }

  data.get(code)[indicator] = rate;
}

// --------------------------------------------------
// Barèmes provisoires
// --------------------------------------------------

function burglaryScore(rate) {

  if (rate == null) return null;

  if (rate === 0) return 8;
  if (rate <= 1) return 7.5;
  if (rate <= 2) return 7;
  if (rate <= 3) return 6.5;
  if (rate <= 4) return 6;
  if (rate <= 5) return 5;
  if (rate <= 7) return 4;
  if (rate <= 10) return 2.5;

  return 1;
}

function vehicleBurglaryScore(rate) {

  if (rate == null) return null;

  if (rate === 0) return 8.5;
  if (rate <= 0.5) return 8;
  if (rate <= 1) return 7.5;
  if (rate <= 2) return 7;
  if (rate <= 3) return 6;
  if (rate <= 4) return 5;
  if (rate <= 6) return 4;
  if (rate <= 10) return 2.5;

  return 1;
}

function vehicleTheftScore(rate) {

  if (rate == null) return null;

  if (rate === 0) return 8.5;
  if (rate <= 0.2) return 8;
  if (rate <= 0.5) return 7.5;
  if (rate <= 1) return 7;
  if (rate <= 2) return 6;
  if (rate <= 3) return 5;
  if (rate <= 5) return 4;
  if (rate <= 7) return 2.5;

  return 1;
}

// --------------------------------------------------
// Calcul du score
// --------------------------------------------------

const results = [];

for (const city of municipalities) {

  const code = String(city.code)
    .padStart(5, "0");

  const values = data.get(code) || {};

  const burglary =
    values["Cambriolages de logement"] ?? null;

  const vehicleBurglary =
    values["Vols dans les véhicules"] ?? null;

  const vehicleTheft =
    values["Vols de véhicule"] ?? null;

  const components = [];

  if (burglary != null) {
    components.push({
      score: burglaryScore(burglary),
      weight: 70
    });
  }

  if (vehicleBurglary != null) {
    components.push({
      score: vehicleBurglaryScore(vehicleBurglary),
      weight: 20
    });
  }

  if (vehicleTheft != null) {
    components.push({
      score: vehicleTheftScore(vehicleTheft),
      weight: 10
    });
  }

  let score = 5;

  if (components.length > 0) {

    const totalWeight =
      components.reduce(
        (sum, item) => sum + item.weight,
        0
      );

    const weightedScore =
      components.reduce(
        (sum, item) =>
          sum + item.score * item.weight,
        0
      );
score =
    weightedScore / totalWeight;

  if (components.length === 2) {
    score = 5 + (score - 5) * 0.85;
  }

  if (components.length === 1) {
    score = 5 + (score - 5) * 0.60;
  }
    
  }

  results.push({
    code,
    name: city.name,

    burglaryRate: burglary,
    vehicleBurglaryRate: vehicleBurglary,
    vehicleTheftRate: vehicleTheft,

    indicatorsAvailable:
      components.length,

    score:
      Math.round(score * 10) / 10
  });
}

// --------------------------------------------------
// Affichage des tests
// --------------------------------------------------

console.log("");
console.log("===== TEST SECURITE V3 =====");
console.log("");

const testCities = [
  "Tautavel",
  "Ille-sur-Têt",
  "Vinça",
  "Marquixanes",
  "Prades",
  "Saint-Paul-de-Fenouillet",
  "Le Boulou",
  "Argelès-sur-Mer",
  "Perpignan"
];
for (const name of testCities) {

  const city = results.find(
    c => c.name === name
  );

  if (!city) {
    console.log(name, "→ NON TROUVÉE");
    continue;
  }

  console.log(name);

  console.log(
    "  Cambriolages :",
    city.burglaryRate ?? "ND"
  );

  console.log(
    "  Vols dans véhicules :",
    city.vehicleBurglaryRate ?? "ND"
  );

  console.log(
    "  Vols véhicule :",
    city.vehicleTheftRate ?? "ND"
  );

  console.log(
    "  Indicateurs :",
    city.indicatorsAvailable
  );

  console.log(
    "  Score :",
    city.score + "/10"
  );

  console.log("");
}
console.log("");
console.log("===== REPARTITION DES SCORES =====");

const distribution = {
  "0-1": 0,
  "1-2": 0,
  "2-3": 0,
  "3-4": 0,
  "4-5": 0,
  "5-6": 0,
  "6-7": 0,
  "7-8": 0,
  "8-9": 0,
  "9-10": 0
};

for (const city of results) {
  const score = city.score;

  if (score < 1) distribution["0-1"]++;
  else if (score < 2) distribution["1-2"]++;
  else if (score < 3) distribution["2-3"]++;
  else if (score < 4) distribution["3-4"]++;
  else if (score < 5) distribution["4-5"]++;
  else if (score < 6) distribution["5-6"]++;
  else if (score < 7) distribution["6-7"]++;
  else if (score < 8) distribution["7-8"]++;
  else if (score < 9) distribution["8-9"]++;
  else distribution["9-10"]++;
}

console.table(distribution);

console.log("");
console.log("===== COMMUNES NOTEES 8/10 OU PLUS =====");

results
  .filter(city => city.score >= 8)
  .sort((a, b) => b.score - a.score)
  .slice(0, 20)
  .forEach(city => {

    console.log("");
    console.log(city.name);

    console.log(
      "  Cambriolages :",
      city.burglaryRate ?? "ND"
    );

    console.log(
      "  Vols dans véhicules :",
      city.vehicleBurglaryRate ?? "ND"
    );

    console.log(
      "  Vols véhicule :",
      city.vehicleTheftRate ?? "ND"
    );

    console.log(
      "  Indicateurs :",
      city.indicatorsAvailable
    );

    console.log(
      "  Score :",
      city.score + "/10"
    );
  });

console.log("");
console.log("===== COMMUNES LES MOINS BIEN NOTEES =====");

results
  .sort((a, b) => a.score - b.score)
  .slice(0, 20)
  .forEach(city => {

    console.log("");
    console.log(city.name);

    console.log(
      "  Cambriolages :",
      city.burglaryRate ?? "ND"
    );

    console.log(
      "  Vols dans véhicules :",
      city.vehicleBurglaryRate ?? "ND"
    );

    console.log(
      "  Vols véhicule :",
      city.vehicleTheftRate ?? "ND"
    );

    console.log(
      "  Indicateurs :",
      city.indicatorsAvailable
    );

    console.log(
      "  Score :",
      city.score + "/10"
    );
  });

console.log("");
console.log("===== TAUX ELEVES VOLS DANS VEHICULES =====");

results
  .filter(city => city.vehicleBurglaryRate != null)
  .sort((a, b) =>
    b.vehicleBurglaryRate - a.vehicleBurglaryRate
  )
  .slice(0, 15)
  .forEach(city => {
    console.log(
      city.name,
      "| taux :",
      city.vehicleBurglaryRate,
      "| score :",
      city.score + "/10"
    );
  });

console.log("");
console.log("===== TAUX ELEVES VOLS DE VEHICULE =====");

results
  .filter(city => city.vehicleTheftRate != null)
  .sort((a, b) =>
    b.vehicleTheftRate - a.vehicleTheftRate
  )
  .slice(0, 15)
  .forEach(city => {
    console.log(
      city.name,
      "| taux :",
      city.vehicleTheftRate,
      "| score :",
      city.score + "/10"
    );
  });

