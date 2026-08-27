export interface CityScores {
  price: number;
  commerce: number;
  health: number;
  safety: number;
  tranquility: number;
  sun: number;
  accessibility: number;
  risk: number;
}

export interface City {
  id: string;
  slug: string;
  name: string;
  region: string;
  lat: number;
  lng: number;
  population: number;
  priceSqm: number;
  sunHours: number;
  scores: CityScores;
}

export interface UserPreferences {
  price: number;
  commerce: number;
  health: number;
  safety: number;
  tranquility: number;
  sun: number;
  accessibility: number;
  risk: number;
}

/**
 * Calcule le score personnalisé d'une ville.
 *
 * Les notes de la ville sont sur 10.
 * Les préférences vont de 0 à 100.
 *
 * Le résultat est compris entre 0 et 100.
 */
export function calculateCityScore(
  city: City,
  preferences: UserPreferences
): number {
  const totalWeight = Object.values(preferences).reduce(
    (total, weight) => total + weight,
    0
  );

  if (totalWeight === 0) {
    return 0;
  }

  const weightedScore =
    city.scores.price * preferences.price +
    city.scores.commerce * preferences.commerce +
    city.scores.health * preferences.health +
    city.scores.safety * preferences.safety +
    city.scores.tranquility * preferences.tranquility +
    city.scores.sun * preferences.sun +
    city.scores.accessibility * preferences.accessibility +
    city.scores.risk * preferences.risk;

  return Math.round((weightedScore / totalWeight) * 10);
}

/**
 * Classe les villes du meilleur score au moins bon.
 */
export function rankCities(
  cities: City[],
  preferences: UserPreferences
): (City & { score: number })[] {
  return cities
    .map((city) => ({
      ...city,
      score: calculateCityScore(city, preferences),
    }))
    .sort((a, b) => b.score - a.score);
}