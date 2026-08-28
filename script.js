let spots = [
  ["Cox's Bazar Sea Beach", "Cox's Bazar", "beach", [21.4159, 91.9810]],
  ["Sundarbans", "Khulna", "nature", [21.9497, 89.1833]],
  ["Somapura Mahavihara", "Naogaon", "history", [25.0311, 88.9769]],
  ["Lalbagh Fort", "Dhaka", "history", [23.7190, 90.3881]],
  ["Sonargaon", "Narayanganj", "history", [23.6445, 90.5984]],
  ["Sixty Dome Mosque", "Bagerhat", "religious", [22.6744, 89.7419]],
  ["Ahsan Manzil", "Dhaka", "history", [23.7086, 90.4061]],
  ["Bandarban", "Bandarban", "nature", [22.2053, 92.2384]],
  ["Rangamati", "Rangamati", "nature", [23.4159, 92.2985]],
  ["Khagrachari", "Khagrachari", "nature", [23.4126, 91.9868]],


  ["Sajek Valley", "Rangamati", "nature", [23.3909, 92.2855]],
  ["Nilgiri","Bandarban","nature"],
  ["Nilachal","Bandarban","nature"],
  ["Thanchi","Bandarban","nature"],
  ["Ruma","Bandarban","nature"],
  ["Keokradong","Bandarban","nature"],
  ["Tajingdong","Bandarban","nature"],
  ["Chimbuk Hill","Bandarban","nature"],
  ["Alikadam","Bandarban","nature"],
  ["Rowangchhari","Bandarban","nature"],

  ["Mahamaya Lake","Chattogram","nature"],
  ["Foy's Lake","Chattogram","nature"],
  ["Patenga Sea Beach","Chattogram","beach"],
  ["Parki Sea Beach","Chattogram","beach"],
  ["Kaptai Lake","Rangamati","nature"],
  ["Hanging Bridge Rangamati","Rangamati","nature"],
  ["Subalong Waterfall","Rangamati","nature"],
  ["Alutila Cave","Khagrachari","nature"],
  ["Richang Waterfall","Khagrachari","nature"],
  ["Dighinala","Khagrachari","nature"],

  ["Saint Martin's Island", "Cox's Bazar", "beach", [20.6131, 92.3267]],
  ["Chera Dwip","Cox's Bazar","beach"],
  ["Teknaf","Cox's Bazar","beach"],
  ["Himchari","Cox's Bazar","beach"],
  ["Inani Beach","Cox's Bazar","beach"],
  ["Kuakata","Patuakhali","beach"],
  ["Sonar Char","Patuakhali","beach"],
  ["Gangamati Beach","Patuakhali","beach"],

  ["Nijhum Island","Noakhali","ecotourism"],
  ["Hatiya Island","Noakhali","nature"],
  ["Sandwip","Chattogram","nature"],
  ["Maheshkhali","Cox's Bazar","nature"],
  ["Kutubdia","Cox's Bazar","nature"],

  ["Shalban Vihara","Cumilla","history"],
  ["Mainamati","Cumilla","history"],

  ["War Cemetery","Chattogram","history"],
  ["Batali Hill","Chattogram","nature"],
  ["Sitakunda","Chattogram","nature"],
  ["Chandranath Temple","Chattogram","religious"],

  ["Tanguar Haor", "Sunamganj", "wetland", [25.1414, 91.0664]],
  ["Hakaluki Haor","Moulvibazar","wetland"],
  ["Srimangal Tea Garden","Moulvibazar","nature"],
  ["Madhabpur Lake","Moulvibazar","nature"],
  ["Ham Ham Waterfall","Moulvibazar","nature"],
  ["Lawachara National Park","Moulvibazar","ecotourism"],

  ["Jaflong","Sylhet","nature"],
  ["Bichanakandi","Sylhet","nature"],
  ["Ratargul Swamp Forest","Sylhet","wetland"],

  ["National Parliament House","Dhaka","city"],
  ["National Martyrs' Memorial","Dhaka","history"],
  ["Baitul Mukarram Mosque","Dhaka","religious"],
  ["Dhakeshwari Temple","Dhaka","religious"],
  ["National Museum","Dhaka","culture"],

  ["Ramna Park","Dhaka","city"],
  ["Suhrawardy Udyan","Dhaka","city"],
  ["Botanical Garden","Dhaka","nature"],
  ["National Zoo","Dhaka","city"],

  ["Bhola Island","Bhola","nature"],
  ["Char Kukri Mukri","Bhola","ecotourism"],
  ["Monpura Island","Bhola","nature"],

  ["Kuakata Sea Beach","Patuakhali","beach"],
  ["Lebur Char","Patuakhali","beach"],
  ["Bhetua Beach","Barguna","beach"],

  ["Padma Bridge","Madaripur","city"],
  ["Mujibnagar","Meherpur","history"],

  ["Hardinge Bridge","Pabna","history"],
  ["Puthia Rajbari","Rajshahi","history"],
  ["Bagha Mosque","Rajshahi","religious"],

  ["Kantajew Temple","Dinajpur","religious"],
  ["Ramsagar","Dinajpur","nature"],

  ["Lalon Akhra","Kushtia","culture"],
  ["Rabindra Kuthibari","Kushtia","culture"]
];

const API_BASE_URL = (window.location.origin === 'null' || window.location.origin.startsWith('file') || window.location.port === '5500' || window.location.port === '5501') ? 'http://127.0.0.1:3000' : window.location.origin;

const budgetRates = {
  transport: { bus: 300, train: 400, launch: 250, air: 2200 },
  hotel: { budget: 600, standard: 1200, premium: 2500 },
  guide: { budget: 900, standard: 1400, premium: 2200 },
  activity: { leisure: 400, culture: 300, adventure: 600, eco: 350, wildlife: 500, family: 300 }
};

const spotFilterProfiles = {
  beach: { budget: 'high', road: 'easy', opportunity: 'leisure' },
  nature: { budget: 'mid', road: 'moderate', opportunity: 'wildlife' },
  history: { budget: 'low', road: 'easy', opportunity: 'culture' },
  religious: { budget: 'low', road: 'easy', opportunity: 'culture' },
  city: { budget: 'high', road: 'easy', opportunity: 'leisure' },
  wetland: { budget: 'mid', road: 'moderate', opportunity: 'eco' },
  ecotourism: { budget: 'low', road: 'easy', opportunity: 'eco' },
  culture: { budget: 'low', road: 'easy', opportunity: 'culture' }
};

const spotFilterOverrides = {
  Sundarbans: { budget: 'high', road: 'moderate', opportunity: 'wildlife' },
  'Saint Martin\'s Island': { budget: 'high', road: 'moderate', opportunity: 'leisure' },
  Nilgiri: { budget: 'high', road: 'challenging', opportunity: 'adventure' },
  'Sajek Valley': { budget: 'mid', road: 'challenging', opportunity: 'adventure' },
  Kuakata: { budget: 'mid', road: 'moderate', opportunity: 'leisure' },
  'Srimangal Tea Garden': { budget: 'mid', road: 'easy', opportunity: 'eco' },
  Jaflong: { budget: 'mid', road: 'moderate', opportunity: 'leisure' }
};

// District coordinates (approximate center of each district)
const districtCoords = {
  "Dhaka": [23.8103, 90.4125],
  "Cox's Bazar": [21.4425, 91.9674],
  "Khulna": [22.8456, 89.5339],
  "Naogaon": [24.1959, 88.9315],
  "Bandarban": [22.2053, 92.2384],
  "Rangamati": [23.4159, 92.2985],
  "Khagrachari": [23.4126, 91.9868],
  "Chattogram": [22.3569, 91.7832],
  "Patuakhali": [22.2526, 90.3298],
  "Noakhali": [23.0137, 91.6309],
  "Cumilla": [23.4607, 91.1809],
  "Sylhet": [24.8949, 91.8687],
  "Sunamganj": [25.2581, 91.3955],
  "Moulvibazar": [24.4829, 91.7271],
  "Narayanganj": [23.6327, 90.5],
  "Bagerhat": [22.6510, 89.7869],
  "Madaripur": [23.1641, 90.1882],
  "Meherpur": [23.7657, 88.6313],
  "Pabna": [23.9169, 89.2334],
  "Rajshahi": [24.3745, 88.6042],
  "Dinajpur": [25.6270, 88.6389],
  "Kushtia": [23.9012, 89.1210]
};

const districtToDivision = {
  "Dhaka": "dhaka",
  "Narayanganj": "dhaka",
  "Madaripur": "dhaka",

  "Chattogram": "chattogram",
  "Cox's Bazar": "chattogram",
  "Bandarban": "chattogram",
  "Rangamati": "chattogram",
  "Khagrachari": "chattogram",
  "Cumilla": "chattogram",
  "Noakhali": "chattogram",

  "Khulna": "khulna",
  "Bagerhat": "khulna",
  "Kushtia": "khulna",
  "Meherpur": "khulna",

  "Patuakhali": "barishal",
  "Bhola": "barishal",
  "Barguna": "barishal",

  "Naogaon": "rajshahi",
  "Rajshahi": "rajshahi",
  "Pabna": "rajshahi",

  "Dinajpur": "rangpur",

  "Sylhet": "sylhet",
  "Sunamganj": "sylhet",
  "Moulvibazar": "sylhet"
};

const divisions = {
  all: "All",
  dhaka: "Dhaka",
  chattogram: "Chattogram",
  khulna: "Khulna",
  sylhet: "Sylhet",
  rangpur: "Rangpur",
  barishal: "Barishal",
  rajshahi: "Rajshahi",
  mymensingh: "Mymensingh"
};

let tourismMap = null;
let mapMarkers = [];
let markerClusterGroup = null;
let useGoogleMaps = true; // set to true to prefer Google Maps when API is loaded
let googleMap = null;
let googleMarkers = [];
window.onGoogleMapsApiLoaded = () => {
  initializeMap();
  if (googleMap) {
    render();
  }
};


const cats = {all:"All", nature:"Nature", beach:"Beach", history:"History", religious:"Religious", culture:"Culture", wetland:"Wetland", ecotourism:"Ecotourism", city:"City"};
let active = "all";
let activeDivision = "all";
let selectedIndex = 0;
// Weather API key should be kept on the server (server/.env). This file calls backend APIs.
// Backend endpoints:
// GET /api/weather?district=Dhaka
// GET /api/forecast?district=Dhaka&date=YYYY-MM-DD


const categoryGradients = {
  all: "linear-gradient(135deg, rgba(70, 201, 109, 0.25), rgba(6, 17, 11, 0.9))",
  nature: "linear-gradient(135deg, rgba(70, 201, 109, 0.35), rgba(6, 17, 11, 0.92))",
  beach: "linear-gradient(135deg, rgba(90, 180, 255, 0.35), rgba(6, 17, 11, 0.92))",
  history: "linear-gradient(135deg, rgba(240, 195, 90, 0.35), rgba(6, 17, 11, 0.92))",
  religious: "linear-gradient(135deg, rgba(255, 120, 100, 0.32), rgba(6, 17, 11, 0.92))",
  culture: "linear-gradient(135deg, rgba(216, 100, 255, 0.32), rgba(6, 17, 11, 0.92))",
  wetland: "linear-gradient(135deg, rgba(78, 209, 190, 0.34), rgba(6, 17, 11, 0.92))",
  ecotourism: "linear-gradient(135deg, rgba(144, 227, 123, 0.34), rgba(6, 17, 11, 0.92))",
  city: "linear-gradient(135deg, rgba(135, 150, 170, 0.34), rgba(6, 17, 11, 0.92))"
};

const spotImages = {
  "Cox's Bazar Sea Beach": "spot-pictures/Coxs bazar.jpg",
  "Sundarbans": "spot-pictures/Sundarban_Tiger.jpg",
  "Lalbagh Fort": "spot-pictures/Lalbagh fort.jpg",
  "Sonargaon": "spot-pictures/Sonargaon .jpg",
  "Ahsan Manzil": "spot-pictures/ahsan-monjil.jpg",
  "Bandarban": "spot-pictures/Bandarban.jpg",
  "Rangamati": "spot-pictures/Rangamati.jpg",
  "Sajek Valley": "spot-pictures/Chittagong hill tracks.jpg",
  "Nilgiri": "spot-pictures/Nilgiri.jpg",
  "Foy's Lake": "spot-pictures/Foys lake.jpg",
  "Patenga Sea Beach": "spot-pictures/Potenga sea Beach .jpg",
  "Saint Martin's Island": "spot-pictures/Saint martin.jpg",
  "Kuakata": "spot-pictures/Kuyakata.jpg",
  "Srimangal Tea Garden": "spot-pictures/SRIMANGAL.jpg",
  "Jaflong": "spot-pictures/Jaflang.jpg",
  "Bichanakandi": "spot-pictures/Bishankandi-4.jpg",
  "Lawachara National Park": "spot-pictures/LAWYACHORA GARDEN.jpg",
  "Ramsagar": "spot-pictures/Ramsagar national park.jpg",
  "Inani Beach": "spot-pictures/Coxs bazar.jpg", // reuse coxs bazar for nearby beaches
  "Himchari": "spot-pictures/Coxs bazar.jpg",
  "Ratargul Swamp Forest": "spot-pictures/Bishankandi-4.jpg", // similar nature
  "Somapura Mahavihara": "https://upload.wikimedia.org/wikipedia/commons/thumb/4/42/Paharpur_Buddhist_Bihar.jpg/1280px-Paharpur_Buddhist_Bihar.jpg",
  "Sixty Dome Mosque": "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4f/Sixty_Dome_Mosque%2CBagerhat.jpg/1280px-Sixty_Dome_Mosque%2CBagerhat.jpg",
  "Khagrachari": "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f4/Midway_to_Konglak_Hill%2C_Khagrachari%2C_Bangladesh.jpg/1280px-Midway_to_Konglak_Hill%2C_Khagrachari%2C_Bangladesh.jpg",
  "Nilachal": "https://upload.wikimedia.org/wikipedia/commons/9/9b/Kamakshya_Shakespeare_Sarani_Arnab_Dutta_2011.jpg",
  "Thanchi": "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a9/Amiakhum_Waterfall.jpg/1280px-Amiakhum_Waterfall.jpg",
  "Ruma": "https://upload.wikimedia.org/wikipedia/commons/thumb/9/94/Keokradong_10.jpg/1280px-Keokradong_10.jpg",
  "Keokradong": "https://upload.wikimedia.org/wikipedia/commons/thumb/1/19/Goodmorning_Keokaradang_%286830453822%29.jpg/1280px-Goodmorning_Keokaradang_%286830453822%29.jpg",
  "Tajingdong": "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1e/Mountains_of_Bangladesh.jpg/1280px-Mountains_of_Bangladesh.jpg",
  "Alikadam": "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d1/Damtua_Waterfall_%288%29.jpg/1280px-Damtua_Waterfall_%288%29.jpg",
  "Rowangchhari": "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1c/%E0%A6%A6%E0%A7%87%E0%A6%AC%E0%A6%A4%E0%A6%BE%E0%A6%96%E0%A7%81%E0%A6%AE%E0%A7%87_%E0%A6%AA%E0%A6%B0%E0%A7%8D%E0%A6%AF%E0%A6%9F%E0%A6%95.jpg/1280px-%E0%A6%A6%E0%A7%87%E0%A6%AC%E0%A6%A4%E0%A6%BE%E0%A6%96%E0%A7%81%E0%A6%AE%E0%A7%87_%E0%A6%AA%E0%A6%B0%E0%A7%8D%E0%A6%AF%E0%A6%9F%E0%A6%95.jpg",
  "Mahamaya Lake": "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1b/Mahamaya_Irrigation_Dam_Regulator_%2810%29.jpg/1280px-Mahamaya_Irrigation_Dam_Regulator_%2810%29.jpg",
  "Kaptai Lake": "https://upload.wikimedia.org/wikipedia/commons/thumb/8/86/Kaptai_Lake_in_Karnafuly%2C_Rangamati.jpg/1280px-Kaptai_Lake_in_Karnafuly%2C_Rangamati.jpg",
  "Hanging Bridge Rangamati": "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1f/Sajek_Valley_01.jpg/1280px-Sajek_Valley_01.jpg",
  "Subalong Waterfall": "https://upload.wikimedia.org/wikipedia/commons/a/a2/%E0%A6%95%E0%A6%BE%E0%A6%AA%E0%A7%8D%E0%A6%A4%E0%A6%BE%E0%A6%87_%E0%A6%B9%E0%A7%8D%E0%A6%B0%E0%A6%A6%2C%E0%A6%AA%E0%A7%8D%E0%A6%AF%E0%A6%BE%E0%A6%A1%E0%A6%BE_%E0%A6%9F%E0%A6%BF%E0%A6%82_%E0%A6%9F%E0%A6%BF%E0%A6%82-36.jpg",
  "Alutila Cave": "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f8/%E0%A6%86%E0%A6%B2%E0%A7%81%E0%A6%9F%E0%A6%BF%E0%A6%B2%E0%A6%BE_%E0%A6%97%E0%A7%81%E0%A6%B9%E0%A6%BE%E0%A6%B0_%E0%A6%AA%E0%A7%8D%E0%A6%B0%E0%A6%AC%E0%A7%87%E0%A6%B6%E0%A6%AE%E0%A7%81%E0%A6%96.JPG/1280px-%E0%A6%86%E0%A6%B2%E0%A7%81%E0%A6%9F%E0%A6%BF%E0%A6%B2%E0%A6%BE_%E0%A6%97%E0%A7%81%E0%A6%B9%E0%A6%BE%E0%A6%B0_%E0%A6%AA%E0%A7%8D%E0%A6%B0%E0%A6%AC%E0%A7%87%E0%A6%B6%E0%A6%AE%E0%A7%81%E0%A6%96.JPG",
  "Dighinala": "https://upload.wikimedia.org/wikipedia/commons/thumb/e/ed/Nature_view._jpg.jpg/1280px-Nature_view._jpg.jpg",
  "Teknaf": "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7a/Teknaf_Ghat.JPG/1280px-Teknaf_Ghat.JPG",
  "Sonar Char": "https://upload.wikimedia.org/wikipedia/commons/thumb/b/bc/%E0%A6%B8%E0%A7%8B%E0%A6%A8%E0%A6%BE%E0%A6%B0_%E0%A6%A4%E0%A6%B0%E0%A7%80-%E0%A6%B0%E0%A6%AC%E0%A7%80%E0%A6%A8%E0%A7%8D%E0%A6%A6%E0%A7%8D%E0%A6%B0%E0%A6%A8%E0%A6%BE%E0%A6%A5_%E0%A6%A0%E0%A6%BE%E0%A6%95%E0%A7%81%E0%A6%B0_-_%E0%A6%B6%E0%A6%BF%E0%A6%B0%E0%A7%8B%E0%A6%A8%E0%A6%BE%E0%A6%AE_%E0%A6%AA%E0%A6%BE%E0%A6%A4%E0%A6%BE_%28%E0%A6%AA%E0%A6%BE%E0%A6%A4%E0%A6%BE_%E0%A7%A8_%E0%A6%95%E0%A6%B0%E0%A7%8D%E0%A6%A4%E0%A6%A8%29.jpg/1280px-%E0%A6%B8%E0%A7%8B%E0%A6%A8%E0%A6%BE%E0%A6%B0_%E0%A6%A4%E0%A6%B0%E0%A7%80-%E0%A6%B0%E0%A6%AC%E0%A7%80%E0%A6%A8%E0%A7%8D%E0%A6%A6%E0%A7%8D%E0%A6%B0%E0%A6%A8%E0%A6%BE%E0%A6%A5_%E0%A6%A0%E0%A6%BE%E0%A6%95%E0%A7%81%E0%A6%B0_-_%E0%A6%B6%E0%A6%BF%E0%A6%B0%E0%A7%8B%E0%A6%A8%E0%A6%BE%E0%A6%AE_%E0%A6%AA%E0%A6%BE%E0%A6%A4%E0%A6%BE_%28%E0%A6%AA%E0%A6%BE%E0%A6%A4%E0%A6%BE_%E0%A7%A8_%E0%A6%95%E0%A6%B0%E0%A7%8D%E0%A6%A4%E0%A6%A8%29.jpg",
  "Gangamati Beach": "https://upload.wikimedia.org/wikipedia/commons/thumb/5/50/%E0%A6%95%E0%A7%81%E0%A6%AF%E0%A6%BC%E0%A6%BE%E0%A6%95%E0%A6%BE%E0%A6%9F%E0%A6%BE_%E0%A6%B8%E0%A6%AE%E0%A7%81%E0%A6%A6%E0%A7%8D%E0%A6%B0_%E0%A6%B8%E0%A7%88%E0%A6%95%E0%A6%A4_05.jpg/1280px-%E0%A6%95%E0%A7%81%E0%A6%AF%E0%A6%BC%E0%A6%BE%E0%A6%95%E0%A6%BE%E0%A6%9F%E0%A6%BE_%E0%A6%B8%E0%A6%AE%E0%A7%81%E0%A6%A6%E0%A7%8D%E0%A6%B0_%E0%A6%B8%E0%A7%88%E0%A6%95%E0%A6%A4_05.jpg",
  "Nijhum Island": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/21/Nijhum_Dwip.jpg/1280px-Nijhum_Dwip.jpg",
  "Hatiya Island": "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7e/Beauty_of_Hatiya5.jpg/1280px-Beauty_of_Hatiya5.jpg",
  "Sandwip": "https://upload.wikimedia.org/wikipedia/commons/d/d1/Nasa_satellite_image_of_Sandwip_Uploaded_by_Rahat.jpg",
  "Kutubdia": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Kutubdia_Batighar_15.jpg/1280px-Kutubdia_Batighar_15.jpg",
  "Shalban Vihara": "https://upload.wikimedia.org/wikipedia/commons/thumb/4/43/Shalbon-vihara-04-by-Sakib-Ahmed-Nasim.jpg/1280px-Shalbon-vihara-04-by-Sakib-Ahmed-Nasim.jpg",
  "Mainamati": "https://upload.wikimedia.org/wikipedia/commons/thumb/9/92/Shalbon_budha_bihar2.jpg/1280px-Shalbon_budha_bihar2.jpg",
  "War Cemetery": "https://upload.wikimedia.org/wikipedia/commons/thumb/1/15/War_cemetery%2C_Chattogram_04.jpg/1280px-War_cemetery%2C_Chattogram_04.jpg",
  "Batali Hill": "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/Batali_Hill_01.jpg/1280px-Batali_Hill_01.jpg",
  "Sitakunda": "https://upload.wikimedia.org/wikipedia/commons/thumb/f/fb/View_from_the_Chandranath_Hill_%2828653837867%29.jpg/1280px-View_from_the_Chandranath_Hill_%2828653837867%29.jpg",
  "Chandranath Temple": "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f0/Chandranath_Temple.jpg/1280px-Chandranath_Temple.jpg",
  "Tanguar Haor": "https://upload.wikimedia.org/wikipedia/commons/thumb/6/62/Tanguar_Haor_1.jpg/1280px-Tanguar_Haor_1.jpg",
  "Hakaluki Haor": "https://upload.wikimedia.org/wikipedia/commons/5/53/Hakaluki_Hawor_in_Dry_Season_Sylhet_Bangladesh.JPG",
  "Madhabpur Lake": "https://upload.wikimedia.org/wikipedia/commons/thumb/0/07/Madhobpur_Lake_%2811%29.JPG/1280px-Madhobpur_Lake_%2811%29.JPG",
  "Ham Ham Waterfall": "https://upload.wikimedia.org/wikipedia/commons/thumb/d/de/HamHam_falls_sylhet.jpg/1280px-HamHam_falls_sylhet.jpg",
  "National Parliament House": "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5f/Emblem_of_the_Jatiya_Sangsad.svg/1280px-Emblem_of_the_Jatiya_Sangsad.svg.png",
  "National Martyrs' Memorial": "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7d/5.%E0%A6%9C%E0%A6%BE%E0%A6%A4%E0%A7%80%E0%A6%AF%E0%A6%BC_%E0%A6%B8%E0%A7%8D%E0%A6%AE%E0%A7%83%E0%A6%A4%E0%A6%BF%E0%A6%B8%E0%A7%8C%E0%A6%A7.jpg/1280px-5.%E0%A6%9C%E0%A6%BE%E0%A6%A4%E0%A7%80%E0%A6%AF%E0%A6%BC_%E0%A6%B8%E0%A7%8D%E0%A6%AE%E0%A7%83%E0%A6%A4%E0%A6%BF%E0%A6%B8%E0%A7%8C%E0%A6%A7.jpg",
  "Baitul Mukarram Mosque": "https://upload.wikimedia.org/wikipedia/commons/thumb/0/09/Baitul_Mukarram_National_Mosque_in_2022.09.jpg/1280px-Baitul_Mukarram_National_Mosque_in_2022.09.jpg",
  "Dhakeshwari Temple": "https://upload.wikimedia.org/wikipedia/commons/thumb/7/77/Main_Temple_of_Dhakeswari.jpg/1280px-Main_Temple_of_Dhakeswari.jpg",
  "National Museum": "https://upload.wikimedia.org/wikipedia/commons/thumb/8/88/Bangladesh_National_Museum_southern_side_%2801%29.jpg/1280px-Bangladesh_National_Museum_southern_side_%2801%29.jpg",
  "Ramna Park": "https://upload.wikimedia.org/wikipedia/commons/e/ee/Romna_Park5.JPG",
  "Suhrawardy Udyan": "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/%E0%A6%86%E0%A6%AE%E0%A6%BE%E0%A6%A6%E0%A7%87%E0%A6%B0_%E0%A6%B2%E0%A6%BE%E0%A6%B2-%E0%A6%B8%E0%A6%AC%E0%A7%81%E0%A6%9C%E0%A7%87%E0%A6%B0_%E0%A6%9C%E0%A6%BE%E0%A6%A4%E0%A7%80%E0%A6%AF%E0%A6%BC_%E0%A6%AA%E0%A6%A4%E0%A6%BE%E0%A6%95%E0%A6%BE%2C_%E0%A6%B6%E0%A6%BF%E0%A6%96%E0%A6%BE_%E0%A6%9A%E0%A6%BF%E0%A6%B0%E0%A6%A8%E0%A7%8D%E0%A6%A4%E0%A6%A8%2C_%E0%A6%B8%E0%A7%8B%E0%A6%B9%E0%A6%B0%E0%A6%BE%E0%A6%93%E0%A6%AF%E0%A6%BC%E0%A6%BE%E0%A6%B0%E0%A7%8D%E0%A6%A6%E0%A7%80_%E0%A6%89%E0%A6%A6%E0%A7%8D%E0%A6%AF%E0%A6%BE%E0%A6%A8%2C_%E0%A6%A2%E0%A6%BE%E0%A6%95%E0%A6%BE%E0%A5%A4.jpg/1280px-thumbnail.jpg",
  "Botanical Garden": "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/%E0%A6%9C%E0%A6%BE%E0%A6%A4%E0%A7%80%E0%A6%AF%E0%A6%BC_%E0%A6%89%E0%A6%A6%E0%A7%8D%E0%A6%AD%E0%A6%BF%E0%A6%A6_%E0%A6%89%E0%A6%A6%E0%A7%8D%E0%A6%AF%E0%A6%BE%E0%A6%A8%2C_%E0%A6%AC%E0%A6%BE%E0%A6%82%E0%A6%B2%E0%A6%BE%E0%A6%A6%E0%A7%87%E0%A6%B6_%E0%A6%AA%E0%A7%8D%E0%A6%B0%E0%A6%AC%E0%A7%87%E0%A6%B6%E0%A6%AA%E0%A6%A5.jpg/1280px-%E0%A6%9C%E0%A6%BE%E0%A6%A4%E0%A7%80%E0%A6%AF%E0%A6%BC_%E0%A6%89%E0%A6%A6%E0%A7%8D%E0%A6%AD%E0%A6%BF%E0%A6%A6_%E0%A6%89%E0%A6%A6%E0%A7%8D%E0%A6%AF%E0%A6%BE%E0%A6%A8%2C_%E0%A6%AC%E0%A6%BE%E0%A6%82%E0%A6%B2%E0%A6%BE%E0%A6%A6%E0%A7%87%E0%A6%B6_%E0%A6%AA%E0%A7%8D%E0%A6%B0%E0%A6%AC%E0%A7%87%E0%A6%B6%E0%A6%AA%E0%A6%A5.jpg",
  "National Zoo": "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Mirpur_national_zoo.jpg/1280px-Mirpur_national_zoo.jpg",
  "Bhola Island": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2d/Bhola_River_by_Jabber_2.JPG/1280px-Bhola_River_by_Jabber_2.JPG",
  "Char Kukri Mukri": "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Chor.Kukri-Mukri.2.jpg/1280px-Chor.Kukri-Mukri.2.jpg",
  "Kuakata Sea Beach": "https://upload.wikimedia.org/wikipedia/commons/thumb/5/50/%E0%A6%95%E0%A7%81%E0%A6%AF%E0%A6%BC%E0%A6%BE%E0%A6%95%E0%A6%BE%E0%A6%9F%E0%A6%BE_%E0%A6%B8%E0%A6%AE%E0%A7%81%E0%A6%A6%E0%A7%8D%E0%A6%B0_%E0%A6%B8%E0%A7%88%E0%A6%95%E0%A6%A4_05.jpg/1280px-%E0%A6%95%E0%A7%81%E0%A6%AF%E0%A6%BC%E0%A6%BE%E0%A6%95%E0%A6%BE%E0%A6%9F%E0%A6%BE_%E0%A6%B8%E0%A6%AE%E0%A7%81%E0%A6%A6%E0%A7%8D%E0%A6%B0_%E0%A6%B8%E0%A7%88%E0%A6%95%E0%A6%A4_05.jpg",
  "Padma Bridge": "https://upload.wikimedia.org/wikipedia/commons/thumb/1/16/The_padma_bridge_02.jpg/1280px-The_padma_bridge_02.jpg",
  "Mujibnagar": "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Mujibnogor_smritisoudho_lal_monch.jpg/1280px-Mujibnogor_smritisoudho_lal_monch.jpg",
  "Hardinge Bridge": "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6e/Hardinge_Bridge_12.jpg/1280px-Hardinge_Bridge_12.jpg",
  "Puthia Rajbari": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/21/Front_of_Puthia_Palace.jpg/1280px-Front_of_Puthia_Palace.jpg",
  "Bagha Mosque": "https://upload.wikimedia.org/wikipedia/commons/thumb/5/59/Bagha_Shahi_Mosque.jpg/1280px-Bagha_Shahi_Mosque.jpg",
  "Kantajew Temple": "https://upload.wikimedia.org/wikipedia/commons/thumb/0/06/Kantaji_Temple_Dinajpur_Bangladesh_%2812%29.JPG/1280px-Kantaji_Temple_Dinajpur_Bangladesh_%2812%29.JPG",
  "Lalon Akhra": "https://upload.wikimedia.org/wikipedia/commons/1/19/Fakir_Lalon_Shah.jpg",
  "Rabindra Kuthibari": "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0e/Shilaidaha_Rabindra_Kuthibadi._5.jpg/1280px-Shilaidaha_Rabindra_Kuthibadi._5.jpg"
};


function getSpotGradient(place) {
  const name = place[0];
  const cat = place[2];
  if (spotImages[name]) {
    return `url('${spotImages[name]}')`;
  }
  return categoryGradients[cat] || categoryGradients.all;
}


function getMarkerColor(category) {
  const colors = {
    nature: '#70c96d',
    beach: '#5ab4ff',
    history: '#f0c35a',
    religious: '#ff6464',
    culture: '#d864ff',
    ecotourism: '#90e37b',
    city: '#8b96aa',
    wetland: '#4ed1be'
  };
  return colors[category] || '#9eb5aa';
}

function initializeMap() {
  const mapContainer = document.getElementById('tourismMap');
  if (!mapContainer) return;

  // If Google Maps is requested and loaded, initialize it. Otherwise fallback to Leaflet.
  if (useGoogleMaps && window.google && window.google.maps) {
    if (googleMap) return;
    googleMap = new google.maps.Map(mapContainer, {
      center: { lat: 23.685, lng: 90.3563 },
      zoom: 7,
      mapTypeControl: true,
    });
    return;
  }

  if (tourismMap) return; // already initialized (Leaflet)

  // Center on Bangladesh (Leaflet fallback)
  tourismMap = L.map('tourismMap').setView([23.685, 90.3563], 7);

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '© OpenStreetMap contributors',
    maxZoom: 19,
    backgroundColor: '#051009'
  }).addTo(tourismMap);

  markerClusterGroup = L.markerClusterGroup({ maxClusterRadius: 50 });
  tourismMap.addLayer(markerClusterGroup);
}

function getMarkerIcon(category, isSelected = false) {
  const color = getMarkerColor(category);
  const size = isSelected ? 30 : 24;
  return L.divIcon({
    html: `<div style="
      width: ${size}px; 
      height: ${size}px; 
      background: ${color}; 
      border: 3px solid ${isSelected ? '#fff' : 'rgba(255,255,255,0.6)'};
      border-radius: 50%; 
      display: grid; 
      place-items: center;
      box-shadow: ${isSelected ? '0 0 12px rgba(255,255,255,0.8), 0 0 20px ' + color : '0 2px 6px rgba(0,0,0,0.4)'};
      font-weight: 700;
      color: #000;
      font-size: ${isSelected ? '14px' : '12px'};
    "></div>`,
    iconSize: [size, size],
    className: 'custom-marker'
  });
}

function clearMapMarkers() {
  if (markerClusterGroup) {
    markerClusterGroup.clearLayers();
    mapMarkers = [];
  }
}

function focusMapOnFilteredPlace(filtered, index) {
  if (!tourismMap || !filtered.length) return;

  const place = filtered[index] || filtered[0];
  if (!place) return;

  const district = place[1];
  const coords = districtCoords[district];
  if (!coords) return;

  tourismMap.flyTo(coords, 8, {
    duration: 0.8,
    easeLinearity: 0.25
  });
}

function addMapMarkers(filtered) {
  clearMapMarkers();
  // Google Maps path
  if (googleMap) {
    filtered.forEach((place, idx) => {
      const [name, district, category, specificCoords] = place;
      const coords = specificCoords || districtCoords[district];
      if (!coords) return;


      const offset = (idx % 3) * 0.01;
      const lat = coords[0] + (Math.random() - 0.5) * 0.05 + offset;
      const lng = coords[1] + (Math.random() - 0.5) * 0.05;

      const pos = { lat, lng };

      const marker = new google.maps.Marker({
        position: pos,
        map: googleMap,
        icon: {
          path: google.maps.SymbolPath.CIRCLE,
          scale: idx === selectedIndex ? 9 : 7,
          fillColor: getMarkerColor(category),
          fillOpacity: 1,
          strokeColor: '#ffffff',
          strokeWeight: 1
        }
      });

      const gLink = `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(name + ' ' + district)}`;
      const info = new google.maps.InfoWindow({ 
        content: `
          <div style="color:#333; padding:5px;">
            <strong style="display:block; font-size:1.1rem; margin-bottom:4px;">${name}</strong>
            <div style="margin-bottom:8px;">${district} • ${cats[category]}</div>
            <div style="display:flex; gap:10px;">
              <a href="destination.html?id=${spots.indexOf(place)}" style="color:#2ea857; font-weight:600; text-decoration:none;">View Details</a>
              <a href="${gLink}" target="_blank" style="color:#4285F4; font-weight:600; text-decoration:none;">Directions</a>
            </div>
          </div>
        ` 
      });


      marker.addListener('click', () => {
        if (selectedIndex === idx) {
          window.location.href = `destination.html?id=${spots.indexOf(place)}`;
        } else {
          selectedIndex = idx;
          render();
        }
        info.open({ map: googleMap, anchor: marker });
      });

      googleMarkers.push({ marker, info });
    });
    return;
  }

  // Leaflet fallback path (existing behaviour)
  if (!tourismMap || !markerClusterGroup) return;

  filtered.forEach((place, idx) => {
    const [name, district, category] = place;
    const coords = districtCoords[district];
    if (!coords) return;

    // Add slight random offset so multiple places in same district don't overlap
    const offset = (idx % 3) * 0.01;
    const lat = coords[0] + (Math.random() - 0.5) * 0.05 + offset;
    const lng = coords[1] + (Math.random() - 0.5) * 0.05;

    const marker = L.marker([lat, lng], {
      icon: getMarkerIcon(category, idx === selectedIndex)
    });

    const popupContent = `
      <strong>${name}</strong>
      <div>${district}</div>
      <div class="category">${cats[category]}</div>
      <div class="map-popup-actions">
        <a href="destination.html?id=${spots.indexOf(place)}">View details</a>
      </div>
    `;
    marker.bindPopup(popupContent);

    marker.on('click', () => {
      if (selectedIndex === idx) {
        window.location.href = `destination.html?id=${spots.indexOf(place)}`;
      } else {
        selectedIndex = idx;
        render();
      }
    });

    mapMarkers.push(marker);
    markerClusterGroup.addLayer(marker);
  });
}

function updateMapMarkers(filtered) {
  // Google Maps path
  if (googleMap) {
    googleMarkers.forEach((obj, idx) => {
      const isSelected = idx === selectedIndex;
      const place = filtered[idx];
      if (!place) return;
      const category = place[2];
      obj.marker.setIcon({
        path: google.maps.SymbolPath.CIRCLE,
        scale: isSelected ? 9 : 7,
        fillColor: getMarkerColor(category),
        fillOpacity: 1,
        strokeColor: '#ffffff',
        strokeWeight: 1
      });
    });
    return;
  }

  if (!tourismMap) return;

  // Leaflet path: Update marker styling based on selected index
  mapMarkers.forEach((marker, idx) => {
    const isSelected = idx === selectedIndex;
    const place = filtered[idx];
    if (place) {
      const category = place[2];
      marker.setIcon(getMarkerIcon(category, isSelected));
    }
  });
}

function focusSearch() {
  const search = document.getElementById("search");
  search.focus();
  search.scrollIntoView({ behavior: "smooth", block: "center" });
}

function jumpToTop() {
  window.scrollTo({ top: 0, behavior: "smooth" });
}

function smoothScrollToSection(selector) {
  const target = document.querySelector(selector);
  if (!target) return;
  target.scrollIntoView({ behavior: "smooth", block: "start" });
}

function initFaqNavigation() {
  document.querySelectorAll('a[href="#faq"]').forEach((link) => {
    link.addEventListener("click", (event) => {
      event.preventDefault();
      smoothScrollToSection("#faq");
    });
  });

  const faqStartBtn = document.getElementById("faqStartBtn");
  if (faqStartBtn) {
    faqStartBtn.addEventListener("click", (event) => {
      event.preventDefault();
      smoothScrollToSection("#discover");
    });
  }
}

function getDivisionByDistrict(district) {
  if (districtToDivision[district]) return districtToDivision[district];
  return null;
}

function getFiltered(includeDivision = true) {
  const q = document.getElementById("search").value.trim().toLowerCase();
  const bF = document.getElementById("budgetFilter")?.value || "All";
  const rF = document.getElementById("roadFilter")?.value || "All";
  const oF = document.getElementById("opportunityFilter")?.value || "All";

  return spots.filter((s) => {
    const division = getDivisionByDistrict(s[1]);
    const profile = spotFilterProfiles[s[2]] || { budget: 'low', road: 'easy', opportunity: 'leisure' };
    const over = spotFilterOverrides[s[0]] || {};
    const p = { ...profile, ...over };

    const matchCat = active === "all" || s[2] === active;
    const matchQ = !q || s[0].toLowerCase().includes(q) || s[1].toLowerCase().includes(q);
    const matchDivision = !includeDivision || activeDivision === "all" || division === activeDivision;
    
    const matchesBudget = bF === "All" || p.budget === bF;
    const matchesRoad = rF === "All" || p.road === rF;
    const matchesOpp = oF === "All" || p.opportunity === oF;

    return matchCat && matchQ && matchDivision && matchesBudget && matchesRoad && matchesOpp;
  });
}

function buildDivisionButtons(source) {
  const divisionGrid = document.getElementById("divisionGrid");
  if (!divisionGrid) return;

  const safeSource = Array.isArray(source) ? source : spots;
  const searchEl = document.getElementById("divisionSearch");
  const divisionQuery = (searchEl?.value || "").trim().toLowerCase();

  const counts = {
    all: safeSource.length,
    dhaka: 0,
    chattogram: 0,
    khulna: 0,
    sylhet: 0,
    rangpur: 0,
    barishal: 0,
    rajshahi: 0,
    mymensingh: 0
  };

  safeSource.forEach((place) => {
    const division = getDivisionByDistrict(place[1]);
    if (division && Object.prototype.hasOwnProperty.call(counts, division)) {
      counts[division] += 1;
    }
  });

  const keys = ["all", "dhaka", "chattogram", "khulna", "sylhet", "rangpur", "barishal", "rajshahi", "mymensingh"];
  const visibleKeys = keys.filter((key) => {
    if (key === "all") return true;
    if (!divisionQuery) return true;
    return divisions[key].toLowerCase().includes(divisionQuery);
  });

  if (!visibleKeys.includes(activeDivision)) {
    activeDivision = "all";
  }

  divisionGrid.innerHTML = "";

  visibleKeys.forEach((key) => {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "division-card" + (key === activeDivision ? " active" : "");
    button.dataset.division = key;
    button.innerHTML =
      "<strong>" + divisions[key] + "</strong>" +
      "<small>" + counts[key] + " destinations</small>";

    button.onclick = () => {
      activeDivision = key;
      selectedIndex = 0;
      render();
    };

    divisionGrid.appendChild(button);
  });
}

function syncCategoryButtons() {
  document.querySelectorAll("[data-cat]").forEach((btn) => {
    btn.classList.toggle("active", btn.dataset.cat === active);
  });
}

function buildCategoryButtons() {
  const catEl = document.getElementById("categoryBar") || document.getElementById("cats");

  if (!catEl) return;

  catEl.innerHTML = "";

  Object.entries(cats).forEach(([key, value]) => {
    const button = document.createElement("button");
    button.className = "chip" + (key === "all" ? " active" : "");
    button.dataset.cat = key;
    button.type = "button";
    button.textContent = value;
    button.onclick = () => {
      active = key;
      selectedIndex = 0;
      syncCategoryButtons();
      render();
    };

    catEl.appendChild(button);
  });
}

function updateStats(filtered) {
  const districts = new Set(spots.map((s) => s[1]));
  document.getElementById("stats").textContent = filtered.length + " places shown";
  document.getElementById("totalPlaces").textContent = spots.length + "+";
  document.getElementById("totalDistricts").textContent = districts.size + "+";
  document.getElementById("activeCategory").textContent = cats[active];
}

function setFeatured(place, idxInFiltered) {
  if (!place) {
    const featuredName = document.getElementById("featuredName");
    if (featuredName) featuredName.textContent = "No destination found";
    const featuredDistrict = document.getElementById("featuredDistrict");
    if (featuredDistrict) featuredDistrict.textContent = "Try another search keyword";
    const featuredTag = document.getElementById("featuredTag");
    if (featuredTag) featuredTag.textContent = "Empty";
    const featuredMeta = document.getElementById("featuredMeta");
    if (featuredMeta) featuredMeta.textContent = "No category";
    
    const resultName = document.getElementById("resultName");
    if (resultName) resultName.textContent = "No destination selected";
    const resultDistrict = document.getElementById("resultDistrict");
    if (resultDistrict) resultDistrict.textContent = "-";
    const resultCategory = document.getElementById("resultCategory");
    if (resultCategory) resultCategory.textContent = "-";
    const resultIndex = document.getElementById("resultIndex");
    if (resultIndex) resultIndex.textContent = "-";
    const resultDesc = document.getElementById("resultDesc");
    if (resultDesc) resultDesc.textContent = "No match found with current filter. Change keyword or select a different category.";
    
    const featuredVisualHero = document.getElementById("featuredVisualHero");
    if (featuredVisualHero) featuredVisualHero.style.backgroundImage = categoryGradients.all;
    const resultVisual = document.getElementById("resultVisual");
    if (resultVisual) resultVisual.style.backgroundImage = categoryGradients.all;

    const aboutName = document.getElementById("aboutName");
    if (aboutName) aboutName.textContent = "No destination found";
    const aboutDesc = document.getElementById("aboutDesc");
    if (aboutDesc) aboutDesc.textContent = "Please try another search keyword.";
    const aboutBestTime = document.getElementById("aboutBestTime");
    if (aboutBestTime) aboutBestTime.textContent = "-";
    const aboutHighlights = document.getElementById("aboutHighlights");
    if (aboutHighlights) aboutHighlights.textContent = "-";
    const aboutTips = document.getElementById("aboutTips");
    if (aboutTips) aboutTips.textContent = "-";
    
    const featuredExploreBtn = document.getElementById("featuredExploreBtn");
    if (featuredExploreBtn) {
      featuredExploreBtn.onclick = null;
      featuredExploreBtn.style.opacity = "0.5";
      featuredExploreBtn.style.cursor = "not-allowed";
    }
    
    const featuredLink = document.getElementById("featuredDetailsLink");
    const resultLink = document.getElementById("resultDetailsLink");
    if (featuredLink) featuredLink.href = "#";
    if (resultLink) resultLink.href = "#";
    return;
  }

  const [name, district, cat] = place;
  const gradient = getSpotGradient(place);

  const featuredName = document.getElementById("featuredName");
  if (featuredName) featuredName.textContent = name;
  const featuredDistrict = document.getElementById("featuredDistrict");
  if (featuredDistrict) featuredDistrict.textContent = district;
  const featuredTag = document.getElementById("featuredTag");
  if (featuredTag) featuredTag.textContent = cats[cat];
  const featuredMeta = document.getElementById("featuredMeta");
  if (featuredMeta) featuredMeta.textContent = "#" + (spots.indexOf(place) + 1) + " in database";

  const resultName = document.getElementById("resultName");
  if (resultName) resultName.textContent = name;
  const resultDistrict = document.getElementById("resultDistrict");
  if (resultDistrict) resultDistrict.textContent = district;
  const resultCategory = document.getElementById("resultCategory");
  if (resultCategory) resultCategory.textContent = cats[cat];
  
  const p = getSpotFilterProfile(place);
  const budgetPill = document.getElementById("resultBudgetPill");
  if (budgetPill) {
    budgetPill.textContent = p.budget.toUpperCase();
    budgetPill.className = 'budget-pill ' + p.budget;
  }

  const budgetResult = document.getElementById("budgetResult");
  if (budgetResult) budgetResult.innerHTML = 'Adjust travelers/nights and click calculate.';

  const routeOptions = document.getElementById("routeOptions");
  if (routeOptions) loadRouteOptions(district);
  
  const resultDesc = document.getElementById("resultDesc");
  if (resultDesc) resultDesc.textContent = name + " is a " + cats[cat].toLowerCase() + " destination in " + district + ". Explore travel options, accommodation, and real-time weather below.";

  const featuredVisualHero = document.getElementById("featuredVisualHero");
  if (featuredVisualHero) featuredVisualHero.style.backgroundImage = gradient;
  const resultVisual = document.getElementById("resultVisual");
  if (resultVisual) resultVisual.style.backgroundImage = gradient;

  const aboutName = document.getElementById("aboutName");
  if (aboutName) aboutName.textContent = name;
  const aboutDesc = document.getElementById("aboutDesc");
  if (aboutDesc) aboutDesc.textContent = place.description || (name + " is a " + cats[cat].toLowerCase() + " destination in " + district + ".");
  const aboutBestTime = document.getElementById("aboutBestTime");
  if (aboutBestTime) aboutBestTime.textContent = place.best_time || "November-February";
  const aboutHighlights = document.getElementById("aboutHighlights");
  if (aboutHighlights) aboutHighlights.textContent = "District: " + district + ". Category: " + cats[cat] + ".";
  const aboutTips = document.getElementById("aboutTips");
  if (aboutTips) aboutTips.textContent = place.tips || "Plan your visit during daylight and bring necessary supplies.";

  // Update links to point to the destination page
  const globalIndex = spots.indexOf(place);
  const featuredExploreBtn = document.getElementById("featuredExploreBtn");
  if (featuredExploreBtn) {
    featuredExploreBtn.style.opacity = "1";
    featuredExploreBtn.style.cursor = "pointer";
    featuredExploreBtn.onclick = () => {
      window.location.href = `destination.html?id=${globalIndex}`;
    };
  }
  const resultLink = document.getElementById("resultDetailsLink");
  if (resultLink) resultLink.href = `destination.html?id=${globalIndex}`;

  // Fetch real-time weather for the excursion route panel
  fetchWeatherFor(district);
}

function renderPopularGrid(filtered) {
  const grid = document.getElementById("popularGrid");
  grid.innerHTML = "";

  filtered.slice(0, 12).forEach((place, idx) => {
    const [name, district, cat] = place;
    const card = document.createElement("article");
    card.className = "popular-card" + (idx === selectedIndex ? " active" : "");
    card.innerHTML =
      '<div class="card-image" style="background-image:' + getSpotGradient(place) + '"></div>' +
      '<div class="card-title"><h3>' + name + '</h3><span class="card-badge">' + cats[cat] + '</span></div>' +
      '<p class="card-meta">District: ' + district + '</p>';

    card.onclick = () => {
      window.location.href = `destination.html?id=${spots.indexOf(place)}`;
    };

    grid.appendChild(card);
  });
}

function getSpotFilterProfile(place) {
  const name = place[0];
  const cat = place[2];
  const profile = spotFilterProfiles[cat] || { budget: 'low', road: 'easy', opportunity: 'leisure' };
  return { ...profile, ...(spotFilterOverrides[name] || {}) };
}

function haversineDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth radius in km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon/2) * Math.sin(dLon/2);
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

// Per-km rates for each comfort-based transport mode (BDT)
const transportPerKmRates = {
  bus_nonac: 1.2,
  bus_ac: 2.2,
  train_nonac: 1.0,
  train_ac: 2.0,
  launch_deck: 0.8,
  launch_cabin: 2.2,
  air: 5.0
};
const transportMinFare = {
  bus_nonac: 80,
  bus_ac: 150,
  train_nonac: 80,
  train_ac: 200,
  launch_deck: 100,
  launch_cabin: 500,
  air: 2000
};

function calculateBudget() {
  const origin = document.getElementById('budgetOrigin')?.value || '';
  const travelers = parseInt(document.getElementById('budgetTravelers')?.value) || 1;
  const nights = parseInt(document.getElementById('budgetNights')?.value) || 1;
  const guideDays = parseInt(document.getElementById('budgetGuideDays')?.value) || 0;
  const transportMode = document.getElementById('budgetTransport')?.value || 'bus_nonac';
  const hotelTier = document.getElementById('budgetHotelTier')?.value || 'normal';
  const guideTier = document.getElementById('budgetGuideTier')?.value || 'none';
  const foodTier = document.getElementById('budgetFoodTier')?.value || 'standard';
  const res = document.getElementById('budgetResult');

  // Get destination district from the currently selected spot
  const destDistrict = document.getElementById('resultDistrict')?.textContent || '';

  if (!origin) {
    if (res) res.innerHTML = '<div style="color:#F5A623;"><i class="fas fa-exclamation-triangle"></i> Please select your district first.</div>';
    return;
  }
  if (!destDistrict || destDistrict === '-') {
    if (res) res.innerHTML = '<div style="color:#F5A623;"><i class="fas fa-exclamation-triangle"></i> Please select a destination first.</div>';
    return;
  }

  // Calculate distance
  const originCoords = districtCoords[origin];
  const destCoords = districtCoords[destDistrict];
  let distKm = 0;
  let distNote = '';

  if (originCoords && destCoords) {
    distKm = haversineDistance(originCoords[0], originCoords[1], destCoords[0], destCoords[1]);
    // Road distance is roughly 1.3x straight-line
    distKm = Math.round(distKm * 1.3);
    let readableTransport = transportMode.replace('_', ' ').toUpperCase();
    distNote = `${origin} → ${destDistrict} (~${distKm} km by ${readableTransport})`;
  } else {
    distKm = 200; // fallback
    distNote = `${origin} → ${destDistrict} (est. ~200 km)`;
  }

  const perKm = transportPerKmRates[transportMode] || 1.2;
  const minFare = transportMinFare[transportMode] || 80;
  const oneWayFare = Math.max(Math.round(distKm * perKm), minFare);
  const roundTripFare = oneWayFare * 2;

  // Lodging rate based on hotelTier choice
  let baseHotelRate = 600;
  if (hotelTier === 'homestay') baseHotelRate = 900;
  else if (hotelTier === '3star') baseHotelRate = 1800;
  else if (hotelTier === '5star') baseHotelRate = 3500;

  // Food rate based on foodTier choice
  let foodRate = 350;
  if (foodTier === 'local') foodRate = 200;
  else if (foodTier === 'premium') foodRate = 750;

  // Tour Guide rate based on guideTier choice (group flat rate)
  let guideRate = 0;
  if (guideTier === 'local') guideRate = 600;
  else if (guideTier === 'professional') guideRate = 1500;

  // Local transport / activities per day per person
  const localTransportRate = 200;

  const transportTotal = roundTripFare * travelers;
  const hotelTotal = baseHotelRate * travelers * nights;
  const foodTotal = foodRate * travelers * (nights + 1);
  const guideTotal = guideRate * (nights + 1);
  const localTransTotal = localTransportRate * travelers * (nights + 1);

  const total = transportTotal + hotelTotal + foodTotal + guideTotal + localTransTotal;

  if (res) {
    res.innerHTML = `
      <div class="budget-total">Estimated: ৳${total.toLocaleString()} BDT</div>
      <div class="budget-breakdown">
        <div><strong>Route:</strong> ${distNote}</div>
        <div><strong>Transport (${transportMode.replace('_', ' ').toUpperCase()}, round-trip):</strong> ৳${transportTotal.toLocaleString()} <small>(৳${oneWayFare.toLocaleString()}/person one-way)</small></div>
        <div><strong>Accommodation (${nights} nights):</strong> ৳${hotelTotal.toLocaleString()}</div>
        <div><strong>Food & Dining (${nights + 1} days):</strong> ৳${foodTotal.toLocaleString()}</div>
        <div><strong>Tour Guide (${nights + 1} days):</strong> ৳${guideTotal.toLocaleString()} <small>(flat group rate)</small></div>
        <div><strong>Local Transport & Activities:</strong> ৳${localTransTotal.toLocaleString()}</div>
      </div>
    `;
  }
}

function showTab(tabName, btn) {
  document.querySelectorAll('.tab-pane').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.tab-button').forEach(b => b.classList.remove('active'));
  document.getElementById(tabName + '-tab').classList.add('active');
  btn.classList.add('active');
}

function loadRouteOptions(district) {
  const container = document.getElementById('routeOptions');
  if (!container) return;
  const externalLinks = [
    { name: 'Sohoz', url: 'https://shohoz.com' },
    { name: 'GoZayan', url: 'https://gozayan.com' },
    { name: 'bdtickets', url: 'https://bdtickets.com' },
    { name: 'ShareTrip', url: 'https://sharetrip.net' }
  ];
  container.innerHTML = `
    <h5>Travel Portals</h5>
    <div class="booking-buttons">
      ${externalLinks.map(link => `<a href="${link.url}" target="_blank" class="button secondary booking-btn">${link.name}</a>`).join('')}
    </div>
  `;
}

async function searchHotels() {
  const list = document.getElementById('hotelResultsList');
  if (!list) return;
  list.innerHTML = 'Searching...';
  
  try {
    const res = await fetch(`${API_BASE_URL}/api/hotels/search`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ city: document.getElementById('resultDistrict').textContent })
    });
    const data = await res.json();
    if (!data.hotels || data.hotels.length === 0) {
      list.innerHTML = 'No specific hotels found.';
      return;
    }
    list.innerHTML = data.hotels.map(h => `
      <div class="hotel-card" style="padding:12px; border:1px solid rgba(255,255,255,0.1); border-radius:12px; margin-bottom:8px;">
        <div style="display:flex; justify-content:space-between; align-items:center;">
          <strong>${h.name}</strong>
          <a href="${h.url}" target="_blank" class="button secondary" style="padding:4px 10px; font-size:0.8rem;">Visit Website</a>
        </div>
        <div style="font-size:0.85rem; color:var(--muted); margin-top:4px;">
          Rating: ${h.rating}★ | Est. ৳${h.price} / night
        </div>
      </div>
    `).join('');
  } catch (e) {
    list.innerHTML = 'Search failed.';
  }
}

function render() {
  const sourceForDivision = getFiltered(false);
  buildDivisionButtons(sourceForDivision);

  const filtered = sourceForDivision.filter((place) => {
    if (activeDivision === "all") return true;
    return getDivisionByDistrict(place[1]) === activeDivision;
  });

  updateStats(filtered);
  renderPopularGrid(filtered);
  addMapMarkers(filtered);
  focusMapOnFilteredPlace(filtered, selectedIndex);

  if (selectedIndex >= filtered.length) {
    selectedIndex = 0;
  }

  setFeatured(filtered[selectedIndex], selectedIndex);
}

// Destination-specific features removed from here, now in destination.js

// Fetch spots from DB and merge with the hardcoded array
async function loadSpotsFromDB() {
  try {
    const res = await fetch(`${API_BASE_URL}/api/spots`);
    if (!res.ok) return;
    const data = await res.json();
    if (!data.spots || !data.spots.length) return;

    // Map DB categories to frontend categories
    const categoryMap = {
      'beach': 'beach', 'nature': 'nature', 'history': 'history', 'historical': 'history',
      'religious': 'religious', 'culture': 'culture', 'wetland': 'wetland',
      'ecotourism': 'ecotourism', 'city': 'city', 'wildlife': 'nature',
      'hill tracks': 'nature', 'mountain': 'nature', 'island': 'beach',
      'lake': 'nature', 'waterfall': 'nature', 'forest': 'ecotourism',
      'general': 'nature'
    };

    // Build a set of existing spot names for deduplication
    const existingNames = new Set(spots.map(s => s[0].toLowerCase()));

    data.spots.forEach(dbSpot => {
      const name = dbSpot.name;
      const district = dbSpot.district_name || 'Unknown';
      const rawCategory = (dbSpot.category || 'nature').toLowerCase();
      const category = categoryMap[rawCategory] || rawCategory;
      const coords = (dbSpot.latitude && dbSpot.longitude) ? [parseFloat(dbSpot.latitude), parseFloat(dbSpot.longitude)] : null;

      // Add to cats if it's a truly new category
      if (!cats[category]) {
        cats[category] = category.charAt(0).toUpperCase() + category.slice(1);
      }

      // Add district coords if we don't have them
      if (coords && district && !districtCoords[district]) {
        districtCoords[district] = coords;
      }

      // Add to districtToDivision if missing
      if (district && dbSpot.division_name && !districtToDivision[district]) {
        districtToDivision[district] = dbSpot.division_name.toLowerCase();
      }

      // Dynamically populate budget override from DB
      if (dbSpot.budget_category) {
        spotFilterOverrides[name] = {
          ...(spotFilterOverrides[name] || {}),
          budget: dbSpot.budget_category.toLowerCase()
        };
      }

      // Find or create spot entry to enrich it
      let entry = spots.find(s => s[0].toLowerCase() === name.toLowerCase());
      if (!entry) {
        entry = [name, district, category];
        if (coords) entry.push(coords);
        spots.push(entry);
        existingNames.add(name.toLowerCase());
      }

      // Attach DB-specific properties to the spot entry
      entry.dbId = dbSpot.id;
      entry.description = dbSpot.description || '';
      entry.history = dbSpot.history || '';
      entry.division = dbSpot.division_name || '';
      entry.budgetCategory = dbSpot.budget_category || '';
      if (dbSpot.image) {
        entry.image = dbSpot.image.startsWith('http') ? dbSpot.image : 'spot-pictures/' + dbSpot.image;
        spotImages[name] = entry.image;
      }
    });
  } catch (e) {
    // Silently fail — hardcoded spots still work as fallback
    console.warn('Could not load spots from DB:', e.message);
  }
}

async function init() {
  const searchEl = document.getElementById("search");
  if (!searchEl) return;

  const divisionSearchEl = document.getElementById("divisionSearch");
  if (divisionSearchEl) {
    divisionSearchEl.addEventListener("input", () => {
      buildDivisionButtons(getFiltered(false));
    });
  }

  // Load DB spots before first render
  await loadSpotsFromDB();

  if (spots && spots.length > 0) {
    selectedIndex = Math.floor(Math.random() * spots.length);
  }

  buildCategoryButtons();
  buildDivisionButtons(spots);
  syncCategoryButtons();
  initFaqNavigation();
  render();

  // Initialize map
  initializeMap();

  // Load home reviews
  loadHomeReviews();
}

async function loadHomeReviews() {
  const container = document.getElementById('homeReviewsList');
  if (!container) return;
  
  try {
    const res = await fetch(`${API_BASE_URL}/api/reviews`);
    const data = await res.json();
    const reviews = data.reviews || [];
    
    // Only 5-star reviews
    const topReviews = reviews.filter(r => r.rating === 5);
    
    if (topReviews.length === 0) {
      container.innerHTML = '<p style="text-align:center; color:var(--muted); padding:30px 0;">No 5-star reviews yet. Be the first to share your experience!</p>';
      return;
    }
    
    container.innerHTML = topReviews.map(r => {
      const initial = (r.userName || 'T').charAt(0).toUpperCase();
      const name = r.userName || 'Traveler';
      const spot = r.spotName || 'Bangladesh';
      const date = r.created_at ? new Date(r.created_at).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' }) : '';
      const replyHtml = r.admin_reply ? `
        <div class="review-card-reply">
          <strong><i class="fas fa-reply"></i> Admin:</strong> ${r.admin_reply}
        </div>` : '';

      return `
        <div class="review-card">
          <div class="review-card-header">
            <div class="review-card-avatar">${initial}</div>
            <div class="review-card-user">
              <div class="review-card-name">${name}</div>
              <div class="review-card-spot"><i class="fas fa-map-marker-alt" style="margin-right:4px;"></i>${spot}</div>
            </div>
          </div>
          <div class="review-card-stars">${starsHTML(r.rating)}</div>
          <div class="review-card-text">"${r.text || 'Amazing experience!'}"</div>
          ${date ? `<div class="review-card-date">${date}</div>` : ''}
          ${replyHtml}
        </div>`;
    }).join('');
  } catch (e) {
    console.error('Error loading home reviews:', e);
  }
}

function starsHTML(r) {
  let s = '';
  for (let i = 1; i <= 5; i++) {
    s += `<i class="fas fa-star" style="color:${i <= r ? '#F5A623' : '#E2E8F0'}"></i>`;
  }
  return s;
}

(async () => { 
  await init(); 
})();


// Fetch current weather from OpenWeather by city/district (Bangladesh assumed)
async function fetchWeatherFor(district) {
  const tabIcon = document.getElementById('tabWeatherIcon');
  const tabTemp = document.getElementById('tabWeatherTemp');
  const tabDesc = document.getElementById('tabWeatherDesc');

  const card = document.getElementById('weatherCard');
  const iconEl = document.getElementById('weatherIcon');
  const tempEl = document.getElementById('weatherTemp');
  const descEl = document.getElementById('weatherDesc');
  const sugEl = document.getElementById('weatherSuggestion');

  if (tabTemp) tabTemp.textContent = 'Loading...';
  if (tabDesc) tabDesc.textContent = district;
  if (tabIcon) tabIcon.textContent = '⏳';

  if (card) card.style.display = 'block';
  if (tempEl) tempEl.textContent = 'Loading...';
  if (descEl) descEl.textContent = district;
  if (sugEl) sugEl.textContent = 'Fetching weather...';

  try {
    const weather = await fetchOpenWeatherCurrent(district);
    const temp = weather.temp;
    const desc = weather.description;
    const main = weather.main;

    const iconStr = chooseIcon(main, desc);
    const suggestion = travelSuggestion(main.toLowerCase(), temp);

    if (tabTemp) tabTemp.textContent = `${temp}°C`;
    if (tabDesc) tabDesc.textContent = `${desc.charAt(0).toUpperCase() + desc.slice(1)} — ${suggestion}`;
    if (tabIcon) tabIcon.textContent = iconStr;

    if (tempEl) tempEl.textContent = `${temp}°C`;
    if (descEl) descEl.textContent = desc;
    if (iconEl) iconEl.textContent = iconStr;
    if (sugEl) sugEl.textContent = suggestion;
  } catch (err) {
    const data = generateMockCurrentWeather(district);
    const temp = Math.round(data.main?.temp ?? 28);
    const desc = (data.weather && data.weather[0] && data.weather[0].description) || 'Clear';
    const main = (data.weather && data.weather[0] && data.weather[0].main) || 'Clear';

    const iconStr = chooseIcon(main, desc);
    const suggestion = travelSuggestion(main.toLowerCase(), temp);

    if (tabTemp) tabTemp.textContent = `${temp}°C`;
    if (tabDesc) tabDesc.textContent = `${desc.charAt(0).toUpperCase() + desc.slice(1)} (Real-time weather unavailable)`;
    if (tabIcon) tabIcon.textContent = iconStr;

    if (tempEl) tempEl.textContent = temp + '°C';
    if (descEl) descEl.textContent = desc;
    if (iconEl) iconEl.textContent = iconStr;
    if (sugEl) sugEl.textContent = `Real-time weather is temporarily unavailable. ${suggestion}`;
  }
}

function chooseIcon(main, desc) {
  const m = (main || '').toLowerCase();
  if (m.includes('rain') || m.includes('drizzle') || m.includes('thunder')) return '🌧️';
  if (m.includes('cloud')) return '☁️';
  if (m.includes('snow')) return '❄️';
  return '☀️';
}

function travelSuggestion(mainLower, temp) {
  if (!mainLower) return 'No suggestion available.';
  if (mainLower.includes('rain') || mainLower.includes('drizzle') || mainLower.includes('thunder')) return 'Not recommended — expect rain. Consider postponing or carry waterproof gear.';
  if (temp >= 35) return 'Hot conditions — avoid midday travel and carry water.';
  if (temp <= 10) return 'Cold conditions — dress warmly and check transport availability.';
  return 'Good conditions for travel — proceed as planned.';
}

const OPENWEATHER_API_KEY = window.OPENWEATHER_API_KEY || 'YOUR_OPENWEATHERMAP_API_KEY';

async function fetchOpenWeatherCurrent(city) {
  const query = encodeURIComponent(`${city},BD`);
  const url = `https://api.openweathermap.org/data/2.5/weather?q=${query}&units=metric&appid=${OPENWEATHER_API_KEY}`;
  const response = await fetch(url);

  if (!response.ok) {
    const payload = await response.json().catch(() => ({}));
    throw new Error(payload?.message || `OpenWeather request failed (${response.status})`);
  }

  const data = await response.json();
  return {
    city: data.name || city,
    temp: Math.round(data.main?.temp ?? 0),
    description: data.weather?.[0]?.description || 'clear sky',
    main: data.weather?.[0]?.main || 'Clear',
  };
}

const weatherLocationCache = new Map();

function normalizeWeatherName(name) {
  return (name ?? '').toString().trim();
}

function weatherCodeToIcon(code, isDay = true) {
  const day = isDay !== false;
  if (code === 0) return day ? '☀️' : '🌙';
  if (code === 1 || code === 2) return day ? '🌤️' : '🌥️';
  if (code === 3) return '☁️';
  if (code === 45 || code === 48) return '🌫️';
  if (code >= 51 && code <= 57) return '🌦️';
  if (code >= 61 && code <= 67) return '🌧️';
  if (code >= 71 && code <= 77) return '❄️';
  if (code >= 80 && code <= 82) return '🌦️';
  if (code >= 95) return '⛈️';
  return '🌤️';
}

function weatherCodeToText(code) {
  if (code === 0) return 'clear sky';
  if (code === 1) return 'mostly clear';
  if (code === 2) return 'partly cloudy';
  if (code === 3) return 'overcast';
  if (code === 45 || code === 48) return 'foggy';
  if (code >= 51 && code <= 57) return 'light drizzle';
  if (code >= 61 && code <= 67) return 'rain';
  if (code >= 71 && code <= 77) return 'snow';
  if (code >= 80 && code <= 82) return 'showers';
  if (code >= 95) return 'thunderstorm';
  return 'weather conditions';
}

function weatherCodeToMain(code) {
  if (code === 0) return 'Clear';
  if (code === 1 || code === 2 || code === 3) return 'Clouds';
  if (code === 45 || code === 48) return 'Mist';
  if (code >= 51 && code <= 67) return 'Rain';
  if (code >= 71 && code <= 77) return 'Snow';
  if (code >= 80 && code <= 82) return 'Rain';
  if (code >= 95) return 'Thunderstorm';
  return 'Clouds';
}

function hashString(value) {
  let hash = 0;
  const text = (value ?? '').toString();
  for (let index = 0; index < text.length; index += 1) {
    hash = ((hash << 5) - hash) + text.charCodeAt(index);
    hash |= 0;
  }
  return Math.abs(hash);
}

function seededNumber(seed, min, max) {
  const span = max - min + 1;
  return min + (seed % span);
}

async function resolveWeatherLocation(district) {
  const name = normalizeWeatherName(district);
  if (!name) throw new Error('District name is required');

  if (weatherLocationCache.has(name)) {
    return weatherLocationCache.get(name);
  }

  const query = encodeURIComponent(`${name}, Bangladesh`);
  const url = `https://geocoding-api.open-meteo.com/v1/search?name=${query}&count=1&language=en&country_code=BD&format=json`;
  const res = await fetch(url);
  if (!res.ok) throw new Error('Location lookup failed');

  const payload = await res.json();
  const place = payload?.results?.[0];
  if (!place) throw new Error(`Could not find weather location for ${name}`);

  const location = {
    name: place.name || name,
    admin1: place.admin1 || '',
    country: place.country || 'Bangladesh',
    latitude: place.latitude,
    longitude: place.longitude,
    timezone: place.timezone || 'auto',
  };

  weatherLocationCache.set(name, location);
  return location;
}

async function fetchOpenMeteoWeather(location) {
  const url = `https://api.open-meteo.com/v1/forecast?latitude=${location.latitude}&longitude=${location.longitude}&current=temperature_2m,weather_code,wind_speed_10m,relative_humidity_2m,is_day&hourly=temperature_2m,weather_code,wind_speed_10m,precipitation_probability&forecast_days=7&timezone=auto`;
  const res = await fetch(url);
  if (!res.ok) throw new Error('Weather lookup failed');
  return res.json();
}

function buildCurrentWeatherFromRealData(location, data) {
  const current = data?.current || {};
  const temp = Math.round(current.temperature_2m ?? 0);
  const code = Number(current.weather_code ?? 0);
  const isDay = current.is_day !== 0;
  const main = weatherCodeToMain(code);
  const description = weatherCodeToText(code);

  return {
    name: location.name,
    main: { temp, humidity: current.relative_humidity_2m ?? 0 },
    weather: [{ main, description, icon: weatherCodeToIcon(code, isDay) }],
    wind: { speed: current.wind_speed_10m ?? 0 },
  };
}

function buildForecastSummaryFromRealData(location, dateVal, data) {
  const hourly = data?.hourly || {};
  const times = Array.isArray(hourly.time) ? hourly.time : [];
  const temps = Array.isArray(hourly.temperature_2m) ? hourly.temperature_2m : [];
  const codes = Array.isArray(hourly.weather_code) ? hourly.weather_code : [];
  const winds = Array.isArray(hourly.wind_speed_10m) ? hourly.wind_speed_10m : [];
  const rainChance = Array.isArray(hourly.precipitation_probability) ? hourly.precipitation_probability : [];

  const indices = [];
  times.forEach((value, index) => {
    if (String(value).slice(0, 10) === dateVal) indices.push(index);
  });

  if (!indices.length) {
    return {
      available: false,
      date: dateVal,
      message: 'No real-time forecast found for that date. Try another date within the next 7 days.',
    };
  }

  let tempMin = Infinity;
  let tempMax = -Infinity;
  let windMax = 0;
  let rainChanceMax = 0;
  let bestIndex = indices[0];
  let bestScore = Infinity;
  const counts = {};

  indices.forEach((index) => {
    const temp = Number(temps[index]);
    const code = Number(codes[index] ?? 3);
    const wind = Number(winds[index] ?? 0);
    const rain = Number(rainChance[index] ?? 0);
    const hour = Number(String(times[index] || '').slice(11, 13) || 12);
    const score = rain + (hour >= 10 && hour <= 15 ? 0 : 8) + (weatherCodeToMain(code) === 'Clear' ? 0 : 5);

    const label = weatherCodeToMain(code);
    counts[label] = (counts[label] || 0) + 1;

    if (Number.isFinite(temp)) {
      tempMin = Math.min(tempMin, temp);
      tempMax = Math.max(tempMax, temp);
    }

    windMax = Math.max(windMax, Math.round(wind));
    rainChanceMax = Math.max(rainChanceMax, Math.round(rain));

    if (score < bestScore) {
      bestScore = score;
      bestIndex = index;
    }
  });

  const dominantMain = Object.entries(counts).sort((a, b) => b[1] - a[1])[0]?.[0] || 'Clear';
  const dominantCode = Number(codes[bestIndex] ?? 0);
  const dominantDescription = weatherCodeToText(dominantCode);
  const safety = getTripSafety(dominantMain.toLowerCase(), Math.round(tempMax), rainChanceMax, windMax);

  let finalTempMax = Number.isFinite(tempMax) ? Math.round(tempMax) : null;
  let finalTempMin = Number.isFinite(tempMin) ? Math.round(tempMin) : null;
  
  if (finalTempMax !== null && finalTempMin !== null) {
    if (finalTempMax - finalTempMin > 2) {
      finalTempMin = finalTempMax - 2;
    }
  }

  return {
    available: true,
    date: dateVal,
    icon: weatherCodeToIcon(dominantCode, true),
    dominantMain,
    dominantDescription,
    tempMin: finalTempMin,
    tempMax: finalTempMax,
    windMax,
    rainChanceMax,
    bestWindow: String(times[bestIndex] || '').slice(11, 16),
    slots: indices.length,
    safety: {
      safe: !/not recommended/i.test(safety),
      label: /not recommended/i.test(safety) ? 'Not safe for long tours' : 'Safe with caution',
      note: safety,
    },
    summary: `${dominantDescription} with up to ${rainChanceMax}% rain chance.`,
    note: safety,
  };
}

// Client-side mock weather (no server needed - works with file://)
function generateMockCurrentWeather(district) {
  const seed = hashString(district || 'Bangladesh');
  const temps = { 'Dhaka': 29, "Cox's Bazar": 28, 'Khulna': 30, 'Rangamati': 22, 'Chattogram': 27, 'Sylhet': 24 };
  const baseTemp = temps[district] || 28;
  const temp = baseTemp; 
  const weatherRoll = seed % 100;
  const main = weatherRoll < 20 ? 'Rain' : (weatherRoll < 50 ? 'Clouds' : 'Clear');
  return {
    mock: true,
    name: district,
    dt: Math.floor(Date.now() / 1000),
    main: { temp, humidity: 70 },
    weather: [{ main, description: main === 'Clear' ? 'clear sky' : 'scattered clouds' }],
    wind: { speed: 3 }
  };
}

function generateMockForecast(district, date) {
  const slots = [];
  const seedBase = hashString(`${district}::${date}`);
  const profileRoll = seedBase % 100;
  const profile = profileRoll < 45 ? 'sunny' : (profileRoll < 80 ? 'cloudy' : 'rainy');
  const [year, month, day] = date.split('-').map(Number);
  for (let h = 0; h < 24; h += 3) {
    const dt = Math.floor(new Date(Date.UTC(year, month - 1, day, h)).getTime() / 1000);
    const slotSeed = seedBase + (h * 17);
    let main = 'Clear', desc = 'clear sky', pop = 0;
    if (profile === 'sunny') {
      if (slotSeed % 16 === 0) { main = 'Clouds'; desc = 'few clouds'; pop = 0.12; }
    } else if (profile === 'cloudy') {
      if (slotSeed % 7 < 2) { main = 'Clouds'; desc = 'broken clouds'; pop = 0.24; }
      if (slotSeed % 11 === 0) { main = 'Rain'; desc = 'light rain'; pop = 0.42; }
    } else {
      if (slotSeed % 6 < 3) { main = 'Rain'; desc = 'light rain'; pop = 0.58; }
      else if (slotSeed % 6 < 5) { main = 'Clouds'; desc = 'overcast'; pop = 0.34; }
    }
    const temps = { 'Dhaka': 29, "Cox's Bazar": 28, 'Khulna': 30, 'Rangamati': 22, 'Chattogram': 27, 'Sylhet': 24 };
    const baseTemp = temps[district] || 28;
    const isDay = h >= 10 && h <= 16;
    const temp = isDay ? baseTemp + 1 : baseTemp;
    slots.push({ dt, main: { temp }, weather: [{ main, description: desc }], pop, wind: { speed: 2 + (h >= 12 ? 1 : 0) } });
  }
  return { mock: true, city: { name: district, timezone: 21600 }, list: slots };
}

function generateMockSummary(district, date, data) {
  const temps = data.list.map(s => s.main.temp);
  const tempMin = Math.min(...temps);
  const tempMax = Math.max(...temps);
  const rainChances = data.list.map(s => s.pop * 100);
  const rainChanceMax = Math.max(...rainChances);
  const winds = data.list.map(s => Math.round((s.wind?.speed || 0) * 3.6));
  const windMax = Math.max(...winds);
  const mains = data.list.map(s => s.weather?.[0]?.main || 'Clear');
  const dominantMain = mains.sort((a, b) => mains.filter(x => x === a).length - mains.filter(x => x === b).length).pop() || 'Clear';
  const desc = data.list.find(s => s.weather?.[0]?.main === dominantMain)?.weather?.[0]?.description || dominantMain.toLowerCase();
  
  let safe = true, label = 'Good for travel', note = 'Weather looks favorable.';
  if (rainChanceMax >= 45 || dominantMain.includes('Rain')) { safe = false; label = 'Not safe for long tours'; note = 'Rain expected. Carry protection or postpone.'; }
  else if (tempMax >= 35) { safe = true; label = 'Safe with caution'; note = 'Hot conditions. Avoid midday travel.'; }
  else if (tempMin <= 10) { safe = true; label = 'Safe with caution'; note = 'Cool conditions. Dress warmly.'; }
  else if (rainChanceMax >= 25) { safe = true; label = 'Safe with caution'; note = 'Some rain chance. Keep an umbrella or raincoat with you.'; }
  
  return {
    available: true,
    date,
    icon: chooseIcon(dominantMain),
    dominantMain,
    dominantDescription: desc,
    tempMin: Math.round(tempMin),
    tempMax: Math.round(tempMax),
    windMax,
    rainChanceMax: Math.round(rainChanceMax),
    bestWindow: '12:00 PM',
    slots: data.list.length,
    safety: { safe, label, note },
    summary: `Mostly ${dominantMain.toLowerCase()} with ${Math.round(rainChanceMax)}% rain chance.`,
    note
  };
}

function forecastSafeClass(summary) {
  if (!summary?.safety) return 'danger';
  if (!summary.safety.safe) return 'danger';
  const label = (summary.safety.label || '').toLowerCase();
  return label.includes('caution') ? 'warn' : 'safe';
}

function renderForecastSummary(summary, district, dateVal) {
  const tempText = summary?.tempMin != null && summary?.tempMax != null
    ? `${summary.tempMin} - ${summary.tempMax}°C`
    : '--°C';
  const rainText = summary?.rainChanceMax != null
    ? `Rain chance up to ${summary.rainChanceMax}%`
    : 'Rain chance unavailable';
  const windText = summary?.windMax != null
    ? `Wind up to ${summary.windMax} km/h`
    : 'Wind info unavailable';
  const safetyLabel = summary?.safety?.label || 'Weather safety unavailable';
  const safetyNote = summary?.safety?.note || summary?.summary || 'No safety note available.';
  const bestWindow = summary?.bestWindow ? `Best window: ${summary.bestWindow}` : 'Best window unavailable';
  const dominant = summary?.dominantMain || 'Weather';
  const description = summary?.dominantDescription || 'Forecast summary';
  const icon = summary?.icon || '🌤️';

  return `
    <div class="forecast-summary">
      <div class="forecast-grid">
        <div class="forecast-pill">
          <strong>${dateVal}</strong>
          <span>${district}</span>
        </div>
        <div class="forecast-pill">
          <strong>${icon} ${dominant}</strong>
          <span>${description}</span>
        </div>
        <div class="forecast-pill">
          <strong>${tempText}</strong>
          <span>Temperature range</span>
        </div>
        <div class="forecast-pill">
          <strong>${rainText}</strong>
          <span>${windText}</span>
        </div>
      </div>
      <div class="forecast-note forecast-safe ${forecastSafeClass(summary)}">${safetyLabel}</div>
      <div class="forecast-note">${safetyNote}</div>
      <div class="forecast-note">${bestWindow}</div>
    </div>
  `;
}

async function fetchForecastForDate(district, dateVal) {
  const iconEl = document.getElementById('weatherIcon');
  const tempEl = document.getElementById('weatherTemp');
  const descEl = document.getElementById('weatherDesc');
  const sugEl = document.getElementById('tripForecastOutput');
  const card = document.getElementById('weatherCard');

  if (!card || !tempEl || !descEl || !sugEl || !iconEl) return;

  card.style.display = 'block';
  tempEl.textContent = 'Loading...';
  descEl.textContent = district;
  iconEl.textContent = '⏳';
  sugEl.textContent = 'Fetching forecast for selected date...';

  try {
    const location = await resolveWeatherLocation(district);
    const apiData = await fetchOpenMeteoWeather(location);
    const summary = buildForecastSummaryFromRealData(location, dateVal, apiData);

    if (summary?.available === false) {
      throw new Error(summary.message || 'No live forecast data available');
    }

    if (summary?.available) {
      tempEl.textContent = summary.tempMin != null && summary.tempMax != null ? `${summary.tempMin} - ${summary.tempMax}°C` : '--°C';
      descEl.textContent = summary.dominantDescription || summary.dominantMain || 'Conditions';
      iconEl.textContent = summary.icon || '🌤️';
      sugEl.innerHTML = renderForecastSummary(summary, district, dateVal);
      return;
    }
  } catch (err) {
    const data = generateMockForecast(district, dateVal);
    const summary = generateMockSummary(district, dateVal, data);
    tempEl.textContent = summary.tempMin != null && summary.tempMax != null ? `${summary.tempMin} - ${summary.tempMax}°C` : '--°C';
    descEl.textContent = summary.dominantDescription || 'Conditions';
    iconEl.textContent = summary.icon || '🌤️';
    sugEl.innerHTML = renderForecastSummary(summary, district, dateVal);
  }
}

function getTripSafety(mainLower, temp, rainChance, windKph) {
  const rc = typeof rainChance === 'number' ? rainChance : 0;
  const windText = windKph != null ? `Windy (~${windKph} km/h)` : '';

  if (mainLower.includes('rain') || mainLower.includes('drizzle') || mainLower.includes('thunder') || rc >= 55) {
    return `Not recommended — expect rain. ${windText ? windText + '. ' : ''}Consider postponing or carry rain protection.`;
  }

  if (temp >= 35) {
    return `Hot conditions — avoid midday travel, rest often, and carry plenty of water.`;
  }

  if (temp <= 10) {
    return `Cool conditions — dress warmly and check local transport timings.`;
  }

  return `Good travel conditions — proceed as planned, but stay aware of quick weather changes.`;
}

