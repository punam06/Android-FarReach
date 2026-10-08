const { districtCoords } = require('./seed');

class ApiError extends Error {
  constructor(status, message) { super(message); this.status = status; }
}
function integer(value, name, min = 1, max = 20) {
  if (!['number', 'string'].includes(typeof value) || !/^\d+$/.test(String(value))) {
    throw new ApiError(400, `${name} must be an integer between ${min} and ${max}`);
  }
  const n = Number(value);
  if (!Number.isSafeInteger(n) || n < min || n > max) throw new ApiError(400, `${name} must be an integer between ${min} and ${max}`);
  return n;
}
function text(value, name, max, required = true) {
  if (typeof value !== 'string' || value.trim().length > max || (required && !value.trim())) {
    throw new ApiError(400, `${name} must be ${required ? 'a nonempty' : 'a'} string of at most ${max} characters`);
  }
  return value.trim();
}
function today() { return new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Dhaka', year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date()); }
function dateOnly(value, name = 'booking_date', future = true) {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)
    || !Number.isFinite(Date.parse(`${value}T00:00:00Z`))
    || new Date(`${value}T00:00:00Z`).toISOString().slice(0, 10) !== value) throw new ApiError(400, `${name} must be a valid YYYY-MM-DD date`);
  if (future && value <= today()) throw new ApiError(400, `${name} must be a future date in Asia/Dhaka`);
  if (future && Date.parse(`${value}T00:00:00Z`) > Date.now() + 366 * 86400000) throw new ApiError(400, `${name} must be within the next year`);
  return value;
}
function choice(value, name, options, fallback) {
  const selected = value === undefined ? fallback : value;
  if (typeof selected !== 'string' || !Object.hasOwn(options, selected)) throw new ApiError(400, `Invalid ${name}`);
  return selected;
}
const budgets = {
  beach: { accommodation: 800, transport: 200 }, nature: { accommodation: 600, transport: 150 },
  history: { accommodation: 700, transport: 150 }, religious: { accommodation: 500, transport: 150 },
  culture: { accommodation: 700, transport: 200 }, city: { accommodation: 1000, transport: 250 },
  ecotourism: { accommodation: 700, transport: 150 }, wetland: { accommodation: 500, transport: 150 },
};
const hotelTiers = { normal: 1, guesthouse: 1.15, homestay: 1.25, beach_resort: 2.9, hill_cottage: 2.5, forest_lodge: 2.3, rest_house: 1.4, '3star': 2.8, boutique: 3.2, '5star': 5.6, luxury_suite: 6.4, others: 2 };
const foodTiers = { street: 180, mess: 240, breakfast: 150, standard: 350, family: 450, fastfood: 320, seafood: 650, hill_cuisine: 520, tea_garden: 380, boat_meal: 500, buffet: 850, fine_dining: 1200, resort_dining: 1000, others: 500 };
const guideTiers = { none: 0, local: 600, licensed: 1500, beach: 850, hill: 1400, forest: 1600, eco: 1100, heritage: 1200, religious: 950, boat: 1000, tribal: 1500, translator: 1200, private_vip: 2500, others: 1200 };
const transportModes = {
  bus_nonac: [1.2, 80], bus_ac: [2.2, 150], bus_sleeper: [2.6, 220], train_shovon: [1, 80],
  train_chair: [1.5, 120], train_ac: [2, 200], train_sleeper: [2.4, 250], launch_deck: [.8, 100],
  launch_cabin: [2.2, 500], ferry: [.9, 120], boat: [.7, 80], microbus: [3.5, 600], private_car: [4.2, 900], cng: [2.8, 180], jeep: [5, 1200], air: [5, 2000],
};
function distance(a, b) {
  const rad = x => x * Math.PI / 180;
  const h = Math.sin(rad(b[0] - a[0]) / 2) ** 2 + Math.cos(rad(a[0])) * Math.cos(rad(b[0])) * Math.sin(rad(b[1] - a[1]) / 2) ** 2;
  return Math.round(6371 * 2 * Math.atan2(Math.sqrt(h), Math.sqrt(Math.max(0, 1 - h))) * 1.3);
}
function packagePrice(spot, persons) {
  return ({ High: 1700, Mid: 1250, Low: 800 }[spot.budget_category] || 800) * persons;
}
function estimate(spot, input) {
  const persons = integer(input.persons === undefined ? 1 : input.persons, 'persons');
  const days = integer(input.days === undefined ? 1 : input.days, 'days', 1, 30);
  const nights = days - 1;
  const origin = text(input.origin === undefined ? 'Dhaka' : input.origin, 'origin', 100);
  const destination = spot.district_name;
  if (!Object.hasOwn(districtCoords, origin) || !Object.hasOwn(districtCoords, destination)) throw new ApiError(400, 'No distance estimate is configured for this district');
  const hotel = choice(input.hotel_tier, 'hotel_tier', hotelTiers, 'normal');
  const food = choice(input.food_tier, 'food_tier', foodTiers, 'standard');
  const guide = choice(input.guide_tier, 'guide_tier', guideTiers, 'none');
  const transport = choice(input.transport_mode, 'transport_mode', transportModes, 'bus_nonac');
  const rates = budgets[String(spot.category).toLowerCase()] || budgets.nature;
  const km = origin === destination ? 0 : distance(districtCoords[origin], districtCoords[destination]);
  const [perKm, minFare] = transportModes[transport];
  const travel = km ? Math.max(Math.round(km * perKm), minFare) * 2 * persons : 0;
  const breakdown = {
    accommodation: Math.round(rates.accommodation * hotelTiers[hotel]) * persons * nights,
    food: foodTiers[food] * persons * days,
    local_transport: rates.transport * persons * days,
    guide: guideTiers[guide] * days,
    round_trip_transport: travel,
  };
  const total = Object.values(breakdown).reduce((a, b) => a + b, 0);
  return { currency: 'BDT', pricing_version: '2026-10-v1', spot_id: spot.id, spot_name: spot.name, origin, destination, persons, days, nights, distance_km: km, hotel_tier: hotel, food_tier: food, guide_tier: guide, transport_mode: transport, breakdown, total, per_person: Math.ceil(total / persons), package_total: packagePrice(spot, persons), estimate_only: true, note: 'Planning estimates, not supplier quotes. Route distance uses a 1.3 road factor; transport modes do not guarantee a route. Package booking is priced separately and excludes these planning extras.' };
}
module.exports = { ApiError, integer, text, dateOnly, today, choice, packagePrice, estimate, hotelTiers, foodTiers, guideTiers, transportModes, districtCoords };
