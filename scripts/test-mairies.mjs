import fs from "fs";
import path from "path";

const filePath = path.resolve("src/data/municipalities.json");

const raw = fs
  .readFileSync(filePath, "utf8")
  .replace(/^\uFEFF/, "");

const cities = JSON.parse(raw);

const testCities = cities.filter(
  (city) =>
    city.name === "Amélie-les-Bains-Palalda" ||
    city.name === "Arles-sur-Tech"
);



const sleep = (ms) =>
  new Promise((resolve) => setTimeout(resolve, ms));

function normalize(text) {
  return String(text || "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .trim();
}

async function findMairie(city) {
  const postalCode =
    city.postalCodes?.[0] ||
    city.codesPostaux?.[0] ||
    "";

  const params = new URLSearchParams({



    q:
  city.name === "Amélie-les-Bains-Palalda"
    ? "Mairie d'Amélie-les-Bains-Palalda, 5 rue des Thermes, 66110"
    : city.name === "Arles-sur-Tech"
      ? "Mairie d'Arles-sur-Tech, 66150"
      : `Mairie ${city.name}, France`,
    
    
    
    
    format: "jsonv2",
    limit: "10",
    addressdetails: "1",
    countrycodes: "fr",
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
    throw new Error(`HTTP ${response.status}`);
  }

  const results = await response.json();

  const cityName = normalize(city.name);

  // On élimine les résultats qui ne sont
  // manifestement pas dans notre commune.
  const candidates = results.filter((result) => {

    const text = normalize(
      result.display_name
    );

    const hasMairie =
      text.includes("mairie");

    const hasCity =
      text.includes(cityName);

    const hasPostalCode =
      !postalCode ||
      text.includes(String(postalCode));

    const isAnnexe =
      text.includes("annexe");

    return (
      hasMairie &&
      hasCity &&
      hasPostalCode &&
      !isAnnexe
    );
  });

  if (!candidates.length) {
    return null;
  }

  return candidates[0];
}

async function main() {

  console.log(
    "TEST DES COORDONNÉES DES MAIRIES"
  );
  console.log("==============================");

  for (const city of testCities) {

    try {

      const result =
        await findMairie(city);

      console.log("");
      console.log(city.name);

      if (result) {

        console.log(
          "→",
          result.lat,
          result.lon
        );

        console.log(
          result.display_name
        );

      } else {

        console.log(
          "→ MAIRIE PRINCIPALE NON TROUVÉE"
        );
      }

    } catch (error) {

      console.log(
        city.name,
        "→ ERREUR :",
        error.message
      );
    }

    // Respect de la limite Nominatim
    await sleep(1100);
  }

  console.log("");
  console.log("==============================");
  console.log("TEST TERMINÉ");
}

main();