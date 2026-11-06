const db = require('./db');
const fs = require('fs');
const path = require('path');

const spotsData = [
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
  "Kushtia": [23.9012, 89.1210],
  "Bhola": [22.6859, 90.6482],
  "Barguna": [22.1586, 90.1261]
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

const spotFilterProfiles = {
  beach: { budget: 'high' },
  nature: { budget: 'mid' },
  history: { budget: 'low' },
  religious: { budget: 'low' },
  city: { budget: 'high' },
  wetland: { budget: 'mid' },
  ecotourism: { budget: 'low' },
  culture: { budget: 'low' }
};

const spotFilterOverrides = {
  Sundarbans: { budget: 'high' },
  'Saint Martin\'s Island': { budget: 'high' },
  Nilgiri: { budget: 'high' },
  'Sajek Valley': { budget: 'mid' },
  Kuakata: { budget: 'mid' },
  'Srimangal Tea Garden': { budget: 'mid' },
  Jaflong: { budget: 'mid' }
};

const spotImages = {
  "Cox's Bazar Sea Beach": "Coxs bazar.jpg",
  "Sundarbans": "Sundarban_Tiger.jpg",
  "Lalbagh Fort": "Lalbagh fort.jpg",
  "Sonargaon": "Sonargaon .jpg",
  "Ahsan Manzil": "ahsan-monjil.jpg",
  "Bandarban": "Bandarban.jpg",
  "Rangamati": "Rangamati.jpg",
  "Sajek Valley": "Chittagong hill tracks.jpg",
  "Nilgiri": "Nilgiri.jpg",
  "Foy's Lake": "Foys lake.jpg",
  "Patenga Sea Beach": "Potenga sea Beach .jpg",
  "Saint Martin's Island": "Saint martin.jpg",
  "Kuakata": "Kuyakata.jpg",
  "Srimangal Tea Garden": "SRIMANGAL.jpg",
  "Jaflong": "Jaflang.jpg",
  "Bichanakandi": "Bishankandi-4.jpg",
  "Lawachara National Park": "LAWYACHORA GARDEN.jpg",
  "Ramsagar": "Ramsagar national park.jpg",
  "Inani Beach": "Coxs bazar.jpg",
  "Himchari": "Coxs bazar.jpg",
  "Ratargul Swamp Forest": "Bishankandi-4.jpg"
};

Object.assign(
  spotImages,
  JSON.parse(
    fs.readFileSync(path.join(__dirname, 'spot-image-sources.json'), 'utf8'),
  ),
);

const firstNames = ['Arif', 'Nusrat', 'Rafiq', 'Maya', 'Tasnim', 'Sujon', 'Jahan', 'Rumana', 'Faruk', 'Lima', 'Kamal', 'Habib', 'Yasmin', 'Zaman', 'Rashed', 'Jamil', 'Tariq', 'Sania', 'Anis', 'Nipa'];
const lastNames = ['Rahman', 'Islam', 'Khan', 'Begum', 'Ahmed', 'Chowdhury', 'Akter', 'Uddin', 'Hassan', 'Ali', 'Siddique', 'Kabir'];
const languagesList = [
  'Bengali, English',
  'Bengali, English, Hindi',
  'Bengali, English, Arabic',
  'Bengali, English, French'
];
const specialtiesList = [
  'Local History, Trekking, Photography',
  'Wildlife, Eco-tourism, Camping',
  'Cultural Tours, Culinary Guiding',
  'Historical Architecture, Photography',
  'Adventure Hiking, Local Tribes & Culture'
];
const experienceOptions = ['2 years', '3 years', '4 years', '5 years', '6 years', '7 years', '8 years'];

async function ensureColumn(table, column, definition) {
  const [rows] = await db.query(
    `SELECT 1
     FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?
     LIMIT 1`,
    [table, column]
  );
  if (rows.length > 0) return;

  // Table, column, and definition are fixed internal values, not user input.
  await db.query(`ALTER TABLE \`${table}\` ADD COLUMN \`${column}\` ${definition}`);
  console.log(`[seeder] Added ${table}.${column}`);
}

async function ensureMobileSchema() {
  await ensureColumn('bookings', 'persons', "INT NOT NULL DEFAULT 1 AFTER booking_date");
  await ensureColumn('reviews', 'admin_reply', 'TEXT NULL AFTER text');
  await ensureColumn('reviews', 'reply_at', 'TIMESTAMP NULL DEFAULT NULL AFTER admin_reply');
}

function buildHistory(name, categoryKey, districtName, divisionName) {
  const place = name;
  const area = districtName || divisionName || 'Bangladesh';
  const category = String(categoryKey || '').toLowerCase();

  if (category.includes('beach') || category.includes('island')) {
    return [
      `Long before ${place} became a name on a travel map, its story was written in tides, salt air and the patient work of coastal families. Fishermen read the colour of the water each morning, boat builders repaired wooden hulls on the sand, and children learned the safe paths between the waves. The shore was never simply scenery; it was a workplace, a road and a gathering place rolled into one.`,
      `As word spread beyond ${area}, traders, pilgrims and curious travellers began to arrive by boat and later by road. Small markets grew where nets were mended and meals were shared, carrying the flavours and languages of several communities. Storms and monsoons repeatedly reshaped the coastline, but the people who lived beside it learned to rebuild with patience, keeping their songs, recipes and local knowledge alive.`,
      `Today ${place} invites visitors to experience that same rhythm at a gentler pace. Sunrise walks, fishing boats returning to shore and evenings beside the water still reveal the character of the place more clearly than any monument. Travel slowly, buy from local families and respect the tides, and the coast will share a story that feels personal rather than packaged.`,
    ].join('\n\n');
  }

  if (category.includes('hill') || category.includes('lake')) {
    return [
      `The story of ${place} begins with the land itself: layered hills, winding roads and water that mirrors the changing sky. For generations, communities in and around ${area} have built their lives around these slopes, growing crops on terraced ground, following forest paths and moving by boat where roads could not reach. The landscape has always demanded cooperation, and that shared effort is part of its identity.`,
      `Over time, traders, travellers and settlers brought new customs into the hills while local traditions held their ground. Markets became meeting places for different communities, and festivals, woven cloth, bamboo craft and stories passed from elders to children. The region changed under kingdoms and modern borders, yet its everyday culture remained rooted in kinship, hospitality and a deep understanding of the terrain.`,
      `For today's traveller, ${place} offers more than a viewpoint or a photograph. It is a chance to move with the pace of the hills, listen to local guides and appreciate how people live alongside forests, water and weather. The most memorable journeys here are the quiet ones: a boat ride at first light, a shared meal in a village, or a conversation that turns a landscape into a living story.`,
    ].join('\n\n');
  }

  if (category.includes('history')) {
    return [
      `The story of ${place} reaches back through layers of settlement, power and memory. The ground around ${area} has witnessed changing rulers, shifting trade routes and the everyday lives of people whose names rarely appear in official records. Walls, gateways and old foundations are only the visible fragments of a much larger story told through labour, craft and local legend.`,
      `Each period left something behind: a style of brickwork, a word in the local dialect, a festival that outlived its original meaning. Merchants and travellers carried ideas along the roads, while craftsmen and farmers kept the settlement alive through seasons of plenty and hardship. What survives today is not simply architecture, but the habit of adapting without forgetting.`,
      `A visit to ${place} is best approached as a walk through time rather than a checklist of monuments. Read the inscriptions slowly, notice the repairs made by later generations and ask local guides about the stories that never made it into textbooks. The past here is not sealed off from the present; it continues in the streets, markets and conversations that surround the old stones.`,
    ].join('\n\n');
  }

  if (category.includes('religious')) {
    return [
      `For generations, ${place} has been more than a landmark; it has been a place where people come to pause, remember and belong. The building and the ground around it grew through gifts of labour, money and faith from families across ${area}. Its courtyards and walls hold the quiet accumulation of prayers, journeys and promises made by ordinary people.`,
      `The history of the site is closely tied to the community that cares for it. Festivals brought distant relatives home, markets gathered around the main entrances, and travellers found shelter nearby. Through changing seasons and political eras, the rituals adapted while the essential purpose remained: to offer a shared space for reflection and renewal.`,
      `Today, visitors of all backgrounds can appreciate ${place} for its craftsmanship, its atmosphere and its place in local life. Dress respectfully, move quietly where people are praying and take time to speak with those who keep the site alive. The deepest history here is not only in the architecture but in the continuing devotion of the people around it.`,
    ].join('\n\n');
  }

  if (category.includes('city')) {
    return [
      `Like many living cities, ${place} grew around movement. Roads, river crossings and marketplaces drew people from surrounding villages, and each new arrival added a craft, a recipe or a way of speaking to the mix. What began as a practical stopping point gradually became a place with its own habits, landmarks and civic pride.`,
      `The city's identity was shaped by work as much as by planning. Traders, clerks, teachers, labourers and students built neighbourhoods around shared needs, while parks, bridges and public buildings gave the growing population places to gather. Periods of rapid change brought new architecture and new tensions, but the streets kept absorbing them, layer by layer.`,
      `Today ${place} is best understood by walking through its ordinary corners as well as its famous ones. Early morning markets, tea stalls, quiet lanes and riverside walks reveal how the city still works. Travellers who slow down and talk to residents will find that the story of the place is being written every day, not only preserved behind glass.`,
    ].join('\n\n');
  }

  if (category.includes('wetland')) {
    return [
      `The story of ${place} is a story of water. Seasonal floods, shallow basins and reed beds have shaped how people fish, farm and move through ${area} for generations. Families learned to read the rising and falling levels, building homes and livelihoods that could bend with the monsoon rather than resist it.`,
      `Life here depends on cooperation. Fishermen, farmers and boatmen share the same channels and the same risks, and local customs often govern when and how resources are used. Birds arrive in great numbers each season, adding another layer to a landscape already rich with sound, movement and changing colour.`,
      `For visitors, ${place} is an invitation to disappear from the usual pace of travel. A boat journey at dawn, a cup of tea with a fishing family or an afternoon beside the water can reveal more than a hurried tour. The wetland asks for patience and care; in return, it offers one of the most memorable natural stories in Bangladesh.`,
    ].join('\n\n');
  }

  if (category.includes('ecotourism')) {
    return [
      `The story of ${place} is rooted in the relationship between people and the natural world. Forests, wetlands and open land around ${area} have long provided food, shelter and materials, and local communities developed careful habits to keep those resources alive. What looks untouched to a visitor is often the result of generations of quiet stewardship.`,
      `In recent decades, the idea of travel as a responsibility has become part of the area's identity. Guides, conservation workers and families have worked to protect wildlife habitats while creating livelihoods that depend on the forest remaining healthy. The balance is never perfect, but it has made the region a place where conservation and everyday life meet.`,
      `A responsible visit to ${place} should begin with listening. Follow your guide, stay on marked paths, avoid plastic and choose local services wherever possible. The reward is a closer look at a landscape that is not a backdrop but a home, and a story in which the traveller can be a respectful guest rather than a passing spectator.`,
    ].join('\n\n');
  }

  if (category.includes('culture')) {
    return [
      `The story of ${place} is carried less by monuments than by memory. Songs, crafts, recipes and the way people greet one another have passed through families and neighbourhoods in ${area} for generations. Each generation has added something of its own while keeping the older forms close.`,
      `Writers, artists, musicians and craftspeople have often gathered here because the place allows room for both tradition and experiment. Festivals and informal meetings created networks that reached far beyond the district, while ordinary households kept the daily practices that give the culture its texture. The result is a heritage that feels lived-in rather than staged.`,
      `Visitors can experience ${place} through its food, markets, workshops and performances, but the most meaningful encounters come from conversation. Ask before taking photographs, support local makers and take time to understand the context behind a song or a design. Culture here is ongoing, and every respectful visitor becomes part of its next chapter.`,
    ].join('\n\n');
  }

  return [
    `The story of ${place} is closely tied to the landscape of ${area}. Rivers, forests, fields or open sky have shaped how people settle, travel and earn a living, and each generation has learned to work with what the land provides. The place may look peaceful at first glance, but its quiet routines are built on knowledge passed down over many years.`,
    `Over time, nearby communities developed their own customs around food, work and hospitality. Markets brought people together, festivals marked the turning of the year, and travellers carried news and ideas along old routes. Change arrived gradually and then more quickly, yet local families continued to adapt without losing the habits that made the place distinctive.`,
    `Today ${place} offers travellers a chance to slow down and see beyond the usual itinerary. Local guides, family-run eateries and small markets reveal a side of the place that a hurried visit cannot reach. Travel with curiosity and respect, and the story of ${place} becomes more than a stop on a map; it becomes a memory shaped by people and place together.`,
  ].join('\n\n');
}

async function seed() {
  console.log('[seeder] Starting database migration & synchronization...');
  
  try {
    // Keep existing databases compatible with the mobile API additions.
    await ensureMobileSchema();

    // 1. Alter spots table enum to support 'Mid'
    await db.query(`
      ALTER TABLE spots 
      MODIFY COLUMN budget_category ENUM('Low', 'Mid', 'High') DEFAULT 'Low'
    `);
    console.log('[seeder] Successfully altered spots budget_category column to support Mid');

    // 1b. Widen spots.image so full image URLs fit.
    await db.query(`ALTER TABLE spots MODIFY COLUMN image TEXT NULL DEFAULT NULL`);
    console.log('[seeder] Successfully widened spots.image column to TEXT');

    // 2. Fetch existing divisions, districts, spots, and guides
    const [divisionsRows] = await db.query('SELECT * FROM divisions');
    const [districtsRows] = await db.query('SELECT * FROM districts');
    const [spotsRows] = await db.query('SELECT * FROM spots');

    const divisionsMap = {}; // name.toLowerCase() -> id
    divisionsRows.forEach(row => {
      divisionsMap[row.name.toLowerCase()] = row.id;
    });

    const districtsMap = {}; // name.toLowerCase() -> id
    districtsRows.forEach(row => {
      districtsMap[row.name.toLowerCase()] = row.id;
    });

    const spotsMap = {}; // name.toLowerCase() -> id
    spotsRows.forEach(row => {
      spotsMap[row.name.toLowerCase()] = row.id;
    });

    // Helper to capitalize first letter
    const capitalize = s => s.charAt(0).toUpperCase() + s.slice(1);

    // 3. Process all 82 spots
    for (const spot of spotsData) {
      const [name, districtName, categoryKey, coords] = spot;
      
      // Determine Division Name
      const divKey = districtToDivision[districtName] || 'dhaka';
      const divisionName = capitalize(divKey);

      // Find or create Division
      let divisionId = divisionsMap[divisionName.toLowerCase()];
      if (!divisionId) {
        const [res] = await db.query('INSERT INTO divisions (name) VALUES (?)', [divisionName]);
        divisionId = res.insertId;
        divisionsMap[divisionName.toLowerCase()] = divisionId;
        console.log(`[seeder] Created division: ${divisionName} (ID: ${divisionId})`);
      }

      // Find or create District
      let districtId = districtsMap[districtName.toLowerCase()];
      if (!districtId) {
        const [res] = await db.query('INSERT INTO districts (name, division_id) VALUES (?, ?)', [districtName, divisionId]);
        districtId = res.insertId;
        districtsMap[districtName.toLowerCase()] = districtId;
        console.log(`[seeder] Created district: ${districtName} under ${divisionName} (ID: ${districtId})`);
      }

      // Determine Category
      const category = capitalize(categoryKey);

      // Determine Coordinates
      const lat = coords ? coords[0] : (districtCoords[districtName] ? districtCoords[districtName][0] : 23.685);
      const lng = coords ? coords[1] : (districtCoords[districtName] ? districtCoords[districtName][1] : 90.3563);

      // Determine Budget
      const rawBudget = spotFilterOverrides[name]?.budget || spotFilterProfiles[categoryKey]?.budget || 'low';
      const budgetCategory = capitalize(rawBudget); // 'Low', 'Mid', or 'High'

      // Determine Image
      const image = spotImages[name] || '';

      const description = `${name} is a beautiful ${categoryKey} spot located in the ${districtName} district of ${divisionName} division.`;
      const history = buildHistory(name, categoryKey, districtName, divisionName);

      let spotId = spotsMap[name.toLowerCase()];
      if (!spotId) {
        // Insert spot
        const [res] = await db.query(`
          INSERT INTO spots 
          (name, district_id, division_id, category, description, history, image, budget_category, latitude, longitude) 
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `, [name, districtId, divisionId, category, description, history, image, budgetCategory, lat, lng]);
        spotId = res.insertId;
        spotsMap[name.toLowerCase()] = spotId;
        console.log(`[seeder] Seeded spot: ${name} (ID: ${spotId})`);
      } else {
        // Keep existing rows synchronized with the canonical destination data.
        await db.query(`
          UPDATE spots 
          SET latitude = ?, longitude = ?, budget_category = ?, category = ?, image = ?,
              history = CASE
                WHEN history IS NULL OR history LIKE '%rich history and cultural significance%'
                THEN ? ELSE history END
          WHERE id = ?
        `, [lat, lng, budgetCategory, category, image, history, spotId]);
      }

      // 4. Populate Guides for this spot
      const [guidesCount] = await db.query('SELECT COUNT(*) as count FROM guides WHERE spot_id = ?', [spotId]);
      const currentCount = guidesCount[0].count;

      if (currentCount < 2) {
        const guidesToInsert = 2 - currentCount;
        const usedNames = new Set();

        for (let i = 0; i < guidesToInsert; i++) {
          let gName = '';
          // Ensure unique names
          do {
            const fn = firstNames[Math.floor(Math.random() * firstNames.length)];
            const ln = lastNames[Math.floor(Math.random() * lastNames.length)];
            gName = `${fn} ${ln}`;
          } while (usedNames.has(gName));
          
          usedNames.add(gName);

          const experience = experienceOptions[Math.floor(Math.random() * experienceOptions.length)];
          const rating = (4.2 + Math.random() * 0.7).toFixed(1); // 4.2 to 4.9
          const languages = languagesList[Math.floor(Math.random() * languagesList.length)];
          const specialties = specialtiesList[Math.floor(Math.random() * specialtiesList.length)];
          const price = 2000 + Math.floor(Math.random() * 7) * 500; // 2000 to 5000 in multiples of 500
          const contact = `+880 171${Math.floor(1 + Math.random() * 9)}-${Math.floor(100000 + Math.random() * 900000)}`;

          await db.query(`
            INSERT INTO guides 
            (name, experience, rating, languages, specialties, price, contact, spot_id) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
          `, [gName, experience, rating, languages, specialties, price, contact, spotId]);
        }
        console.log(`[seeder] Generated ${guidesToInsert} guides for spot: ${name}`);
      }
    }

    console.log('[seeder] Database migration and seeding successfully completed!');
  } catch (err) {
    console.error('[seeder] Error during database seeding:', err.message);
    throw err;
  }
}

module.exports = seed;
