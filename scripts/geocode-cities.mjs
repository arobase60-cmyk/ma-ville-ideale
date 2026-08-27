import fs from "fs";
import path from "path";

const filePath = path.resolve("src/data/municipalities.json");

const raw = fs.readFileSync(filePath, "utf8").replace(/^\uFEFF/, "");

const cities = JSON.parse(raw);

const sleep = (ms) =>
  new Promise((resolve) => setTimeout(resolve, ms));

async function geocodeCity(city) {
  const params = new URLSearchParams({
    q: `${city.name}, France`,
    format: "jsonv2",
    limit: "5",
    addressdetails: "1",
    countrycodes: "fr",
    featuretype: "settlement",
    "accept-language": "fr"
  });

  const url =
    `https://nominatim.openstreetmap.org/search?${params}`;

  const response = await fetch(url, {
    headers: {
      "User-Agent":
        "MaVilleIdeale/1.0 (projet personnel)"
    }
  });

  if (!response.ok) {
    throw new Error(
      `HTTP ${response.status}`
    );
  }

  const results = await response.json();

  if (!results.length) {
    return null;
  }

  // On privilégie un résultat correspondant
  // réellement au nom de la commune.
  const exact = results.find(
    (result) =>
      result.name?.toLowerCase() ===
      city.name?.toLowerCase()
  );

  const result = exact || results[0];

  return {
    mapLat: Number(result.lat),
    mapLng: Number(result.lon)
  };
}

async function main() {
  console.log(
    `Communes à traiter : ${cities.length}`
  );

  let success = 0;
  let failed = 0;

  for (let i = 0; i < cities.length; i++) {
    const city = cities[i];

    // Ne pas refaire une commune déjà traitée
    if (
      city.mapLat != null &&
      city.mapLng != null
    ) {
      console.log(
        `[${i + 1}/${cities.length}] ${city.name} : déjà fait`
      );
      success++;
      continue;
    }

    try {
      const coordinates =
        await geocodeCity(city);

      if (coordinates) {
        city.mapLat =
          coordinates.mapLat;

        city.mapLng =
          coordinates.mapLng;

        console.log(
          `[${i + 1}/${cities.length}] ${city.name} → ${city.mapLat}, ${city.mapLng}`
        );

        success++;
      } else {
        console.log(
          `[${i + 1}/${cities.length}] ${city.name} → NON TROUVÉ`
        );

        failed++;
      }

    } catch (error) {
      console.error(
        `[${i + 1}/${cities.length}] ${city.name} → ERREUR`,
        error.message
      );

      failed++;
    }

    // Nominatim : maximum 1 requête/seconde
    await sleep(1100);
  }

  fs.writeFileSync(
    filePath,
    JSON.stringify(cities, null, 2),
    "utf8"
  );

  console.log("");
  console.log("==============================");
  console.log("GEOCODAGE TERMINE");
  console.log("==============================");
  console.log(`Réussies : ${success}`);
  console.log(`Échecs   : ${failed}`);
  console.log("==============================");
}

main();